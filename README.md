# website_dailycrawler_textanalysis

Web Crawler for Text Data
This repository contains a work-in-progress R script for a web crawler designed to scrape text data from the United Nations Press Release website (https://press.un.org/en). The primary goal of this crawler is to collect text data daily for subsequent text analysis, including word-to-vector analysis, topic modeling, and sentiment analysis.

Features
Daily Scraping: Automatically scrapes new text content from specified sections of the UN Press Release website.
Data Storage: Saves the scraped text data with a timestamp, gradually building a dataset over time.
Text Analysis: Includes basic functions for processing and analyzing the collected text data, such as:
Sentiment analysis
Frequency analysis of terms and bigrams
Topic modeling using LDA (Latent Dirichlet Allocation)
t-SNE visualization of word vectors for identifying clusters
Requirements
R (version 4.0 or higher recommended)
RStudio (optional, but recommended for ease of use)

Configuration: Set the target URL and sections you wish to scrape in the script. Adjust the CSS selectors as needed based on the website's structure.
Scheduling: Use cronR on Linux/Mac or Task Scheduler on Windows to schedule the script to run daily.
