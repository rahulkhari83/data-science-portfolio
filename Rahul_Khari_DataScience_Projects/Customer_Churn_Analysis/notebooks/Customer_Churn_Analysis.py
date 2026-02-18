# Customer Churn Analysis (Python) - Portfolio Project
# Author: Rahul Khari
#
# Run:
#   pip install -r requirements.txt
#   cd notebooks
#   python Customer_Churn_Analysis.py

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, roc_auc_score, confusion_matrix
import matplotlib.pyplot as plt

df = pd.read_csv("../data/customer_churn.csv")

print("Rows, Cols:", df.shape)
print("Churn rate:", round(df["churn"].mean(), 3))

churn_by_contract = df.groupby("contract_type")["churn"].mean().sort_values(ascending=False)
print("\nChurn by contract type:\n", churn_by_contract)

churn_by_contract.plot(kind="bar")
plt.title("Churn Rate by Contract Type")
plt.ylabel("Churn Rate")
plt.tight_layout()
plt.show()

X = df.drop(columns=["churn","customer_id"])
y = df["churn"]

cat_cols = ["contract_type","internet_service"]
num_cols = [c for c in X.columns if c not in cat_cols]

pre = ColumnTransformer([
    ("cat", OneHotEncoder(handle_unknown="ignore"), cat_cols),
    ("num", "passthrough", num_cols),
])

clf = Pipeline([
    ("preprocess", pre),
    ("model", LogisticRegression(max_iter=2000))
])

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=42, stratify=y
)

clf.fit(X_train, y_train)
preds = clf.predict(X_test)
proba = clf.predict_proba(X_test)[:,1]

print("\nClassification Report:\n", classification_report(y_test, preds))
print("ROC-AUC:", round(roc_auc_score(y_test, proba), 3))
print("Confusion Matrix:\n", confusion_matrix(y_test, preds))

print("\nBusiness Recommendations:")
print("- Retention offers for month-to-month customers (highest churn).")
print("- Reduce support calls via better onboarding and proactive support.")
print("- Encourage autopay to reduce churn risk.")
