install.packages(c("rvest", "tidyverse", "lubridate", "tm", "wordcloud", "wordcloud2", "topicmodels", "ggplot2", "text2vec", "cronR", "reshape2"))


library(rvest)
library(tidyverse)
library(lubridate)

scrape_text_data <- function(url) {
  page <- read_html(url)
  text_data <- page %>% html_elements("p") %>% html_text()
  return(text_data)
}

url <- "https://press.un.org/en"
text_data <- scrape_text_data(url)
writeLines(text_data, paste0("text_data_", Sys.Date(), ".txt"))


library(cronR)
script_path <- "/Users/williamchristiansen/Documents/Research/SentimentAnalysis/crawler.R"
cmd <- cron_rscript(script_path)
cron_add(cmd, frequency = "daily", at = "14:00")



##### process and manage text 

library(tm)

preprocess_text <- function(text_vector) {
  corpus <- Corpus(VectorSource(text_vector))
  corpus_clean <- corpus %>%
    tm_map(content_transformer(tolower)) %>%
    tm_map(removePunctuation) %>%
    tm_map(removeNumbers) %>%
    tm_map(removeWords, stopwords("en")) %>%
    tm_map(stripWhitespace)
  return(corpus_clean)
}

text_data_clean <- preprocess_text(text_data)

#### Analysis

library(text2vec)

it <- itoken(text_data_clean$content, progressbar = FALSE)
vocabulary <- create_vocabulary(it)
vectorizer <- vocab_vectorizer(vocabulary)
dtm <- create_dtm(it, vectorizer)

it <- itoken(text_data_clean, progressbar = FALSE)
vocabulary <- create_vocabulary(it) 
vectorizer <- vocab_vectorizer(vocabulary)

# Create the document-term co-occurrence matrix with the 'create_tcm' function
tcm <- create_tcm(it, vectorizer, skip_grams_window = 5L)

# Initialize the GloVe model
glove_model <- GloVe$new(rank = 50, x_max = 10)

# Fit the model on the co-occurrence matrix
word_vectors <- glove_model$fit_transform(tcm, n_iter = 1000, convergence_tol = 0.01, n_threads = 1)

# Normalize word vectors (optional but often recommended)
normalize_vectors <- function(vectors) {
  sqrt_row_sums <- sqrt(rowSums(vectors^2))
  return(vectors / sqrt_row_sums)
}

word_vectors_normalized <- normalize_vectors(word_vectors)


library(topicmodels)

dtm <- DocumentTermMatrix(text_data_clean)
lda_model <- LDA(dtm, k = 5)
topics <- tidy(lda_model)
print(topics)

# Assuming `lda_model` is your fitted LDA model
# Get the terms from the model
terms <- terms(lda_model, 5) # Extract top 10 terms for each topic

# Convert to data frame for plotting
terms_df <- as.data.frame(terms)
terms_df$topic <- rownames(terms_df)

# Melt the data frame for ggplot
library(tidyr)
terms_long <- pivot_longer(terms_df, -topic, names_to = "TermRank", values_to = "Term")

# Plot using ggplot2
ggplot(terms_long, aes(x = Term, y = topic, fill = topic)) +
  geom_tile() +
  facet_wrap(~ topic, scales = "free_y") +
  labs(title = "Top Terms in Each Topic", x = "Term", y = "Topic") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

### Graphs

library(ggplot2)

word_freqs <- data.frame(term = vocabulary$term, freq = vocabulary$term_count) %>%
  arrange(desc(freq)) %>%
  head(20)

ggplot(word_freqs, aes(x = reorder(term, freq), y = freq)) +
  geom_col() +
  coord_flip() +
  labs(title = "Top 20 Word Frequencies", x = "Term", y = "Frequency") +
  theme_minimal()


## Graph Glove model

# Assuming word_vectors_normalized is a matrix of word vectors
pca_result <- prcomp(word_vectors_normalized)

# Use the first two principal components for plotting
word_vectors_2d <- as.data.frame(pca_result$x[, 1:2])

# Assuming 'vocabulary' is your list or vector of words corresponding to the rows in word_vectors_normalized
word_vectors_2d$word <- rownames(word_vectors_normalized)  # or use your vocabulary list if rownames are not set

library(ggplot2)

ggplot(word_vectors_2d, aes(x = PC1, y = PC2, label = word)) +
  geom_text(aes(label = word), check_overlap = TRUE, size = 3) +
  labs(title = "2D Visualization of Word Vectors",
       x = "Principal Component 1",
       y = "Principal Component 2") +
  theme_minimal()

## optional

# Install and load the Rtsne package
if (!require("Rtsne")) install.packages("Rtsne")
library(Rtsne)

# Perform t-SNE
tsne_result <- Rtsne(word_vectors_normalized)

# Prepare data for plotting
tsne_data <- as.data.frame(tsne_result$Y)
colnames(tsne_data) <- c("Dim1", "Dim2")
tsne_data$word <- rownames(word_vectors_normalized)  # or your vocabulary list

# Plot
ggplot(tsne_data, aes(x = Dim1, y = Dim2, label = word)) +
  geom_text(aes(label = word), check_overlap = TRUE, size = 3) +
  labs(title = "t-SNE Visualization of Word Vectors",
       x = "Dimension 1",
       y = "Dimension 2") +
  theme_minimal()


# Assuming `lda_model` is your fitted LDA model
# Extract the document-topic distribution
doc_topics <- as.data.frame(lda_model@gamma)

# Add a document ID column
doc_topics$document <- rownames(doc_topics)

# Melt the data frame for ggplot
doc_topics_long <- pivot_longer(doc_topics, -document, names_to = "Topic", values_to = "Distribution")

# Plot using ggplot2
ggplot(doc_topics_long, aes(x = document, y = Distribution, fill = Topic)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(title = "Topic Distribution Across Documents", x = "Document", y = "Topic Distribution") +
  theme(axis.text.x = element_text(angle = 90,hjust = 1, vjust = 0.5))
p

