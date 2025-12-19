import io
import base64
import numpy as np
from PIL import Image
from flask import Flask, request, jsonify
import mediapipe as mp
import pickle
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend access

# Load trained gesture classifier
with open("gesture_classifier.pkl", "rb") as f:
    classifier = pickle.load(f)

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.8
)

# Lower threshold for recognition (set to 0.5)
RECOGNITION_THRESHOLD = 0.8

@app.route('/detect_hand', methods=['POST'])
def detect_hand():
    try:
        data = request.get_json()
        image_data = data.get('image')
        if image_data is None:
            return jsonify({'error': 'No image provided'}), 400

        # Decode the Base64 image.
        image_bytes = base64.b64decode(image_data)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        image_np = np.array(image)

        # Process image to extract hand keypoints.
        results = hands.process(image_np)
        all_features = []

        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                features = []
                for lm in hand_landmarks.landmark:
                    features.extend([lm.x, lm.y, lm.z])
                all_features.append(features)

            if all_features:
                # Use predict_proba to check confidence.
                probs = classifier.predict_proba([all_features[0]])[0]
                max_prob = max(probs)
                print(f"Probabilities: {probs}  Max probability: {max_prob}")

                if max_prob < RECOGNITION_THRESHOLD:
                    predicted_gesture = "Sign not recognized"
                else:
                    predicted_gesture = classifier.predict([all_features[0]])[0]
                    if predicted_gesture.lower() == "unknown":
                        predicted_gesture = "Sign not recognized"

                print(f"Predicted Gesture: {predicted_gesture}")
                return jsonify({
                    'gesture': predicted_gesture,
                    'keypoints': all_features
                })

        # No hands detected
        return jsonify({'gesture': "", 'keypoints': []})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
