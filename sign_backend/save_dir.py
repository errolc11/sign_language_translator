import cv2
import os
import time

# Define the folder where images will be saved.
save_dir = r"C:\sign_backend\data2\1"
if not os.path.exists(save_dir):
    os.makedirs(save_dir)

# Open the default webcam.
cap = cv2.VideoCapture(0)

# Set the interval (in seconds) between captures.
capture_interval = 5  # Change this value as needed.
last_capture_time = time.time()

print("Press 'q' to quit the capture loop.")

while True:
    ret, frame = cap.read()
    if not ret:
        print("Failed to capture frame from webcam. Exiting.")
        break

    # Display the live webcam feed.
    cv2.imshow("Webcam", frame)

    # Check if enough time has passed to capture a new image.
    if time.time() - last_capture_time >= capture_interval:
        # Generate a unique filename using the current timestamp.
        timestamp = int(time.time() * 1000)  # Milliseconds
        filename = os.path.join(save_dir, f"image_{timestamp}.jpg")
        cv2.imwrite(filename, frame)
        print(f"Saved image: {filename}")
        last_capture_time = time.time()

    # Exit if 'q' is pressed.
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release resources.
cap.release()
cv2.destroyAllWindows()
