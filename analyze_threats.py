import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer

# 1. Load the actual Kaggle dataset
try:
    file_name = 'cyber-threat-intelligence_all.csv'
    df = pd.read_csv(file_name)
    print(f"--- DataLock AI Research: {file_name} Loaded ---")
    # 2. Analyze the Threat Labels
    # We want to see how common 'Data Capture' or 'Exfiltration' threats are
    label_counts = df['label'].value_counts()
    print("\n[STEP 1] Top Threat Categories in Dataset:")
    print(label_counts.head(5))

    # 3. NLP Analysis: Finding 'Exfiltration' keywords
    # We analyze the 'text' column to find technical terms related to Data Capture
    vectorizer = CountVectorizer(stop_words='english', max_features=10)
    X = vectorizer.fit_transform(df['text'].dropna())
    keywords = vectorizer.get_feature_names_out()

    print("\n[STEP 2] Key Technical Signatures Identified:")
    print(keywords)

    # 4. Linking to Mobile App (The Heuristic Connection)
    print("\n--- AI RESEARCH CONCLUSION ---")
    if 'exfiltration' in str(label_counts.index).lower() or 'capture' in str(label_counts.index).lower():
        print("Finding: 'Data Exfiltration' is a significant threat in the intelligence logs.")
        print("Decision: DataLock Mobile App will implement HIGH-SENSITIVITY alerts for rapid interactions.")
    else:
        print("Finding: General threats identified. Implementing proactive monitoring for all UI interactions.")

except Exception as e:
    print(f"Analysis Error: {e}")