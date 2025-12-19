import os
import cv2
import csv
import mediapipe as mp

# Initialize MediaPipe Hands in static mode for images.
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=1,
    min_detection_confidence=0.7
)

dataset_dir = r"C:\sign_backend\images"  # add sign images to images folder
output_csv = "keypoints_data.csv"

print("Starting keypoint extraction from:", dataset_dir)

with open(output_csv, mode="w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    # Write header: feat1, feat2, ..., feat63, label
    header = [f"feat{i+1}" for i in range(63)] + ["label"]
    writer.writerow(header)

    # Iterate over every item in the dataset directory
    for label in os.listdir(dataset_dir):
        label_path = os.path.join(dataset_dir, label)
        if os.path.isdir(label_path):
            print(f"Processing folder (label): {label}")
            for image_file in os.listdir(label_path):
                if image_file.lower().endswith((".jpg", ".jpeg", ".png")):
                    image_path = os.path.join(label_path, image_file)
                    print(f"  Processing image: {image_file}")
                    image = cv2.imread(image_path)
                    if image is None:
                        print(f"    Warning: Could not read {image_path}")
                        continue
                    # Convert BGR image to RGB.
                    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                    results = hands.process(image_rgb)
                    if results.multi_hand_landmarks:
                        # Use the first detected hand.
                        hand_landmarks = results.multi_hand_landmarks[0]
                        features = []
                        for lm in hand_landmarks.landmark:
                            features.extend([lm.x, lm.y, lm.z])
                        writer.writerow(features + [label])
                    else:
                        print(f"    No hand detected in {image_path}")
        else:
            print(f"Skipping non-directory item: {label}")

print("Extraction complete. Data saved to", output_csv)
