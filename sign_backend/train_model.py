import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score
import pickle

print("Loading dataset from keypoints_data.csv...")
# Load CSV data; low_memory=False helps with type inference.
data = pd.read_csv("keypoints_data.csv", low_memory=False)
print("Dataset loaded. Shape:", data.shape)

# Separate features (first 63 columns) and labels (last column).
X = data.iloc[:, :-1].values
y = data.iloc[:, -1].values

print("Splitting dataset into train and test sets...")
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

unique_classes = set(y_train)
print("Unique classes in training data:", unique_classes)

if len(unique_classes) < 2:
    print("Error: The dataset contains only one class. Please add samples from at least one more class before training a classifier.")
    clf = None
else:
    print("Training the classifier...")
    clf = SVC(kernel='linear', probability=True)
    clf.fit(X_train, y_train)

    print("Evaluating classifier on test data...")
    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print("Test Accuracy: {:.2f}%".format(acc * 100))

    # Save the trained model to a pickle file.
    with open("gesture_classifier.pkl", "wb") as f:
        pickle.dump(clf, f)
    print("Model training complete and saved as gesture_classifier.pkl")
