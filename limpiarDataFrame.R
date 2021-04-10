transform_and_clean_tweets <- function(filename, remove_rts, lugar){
  
  # Import the normalize_text function
  source("norm.R")
  df <- filename
  
  # If remove_rst = TRUE, filter out all the retweets from the stream
  if(remove_rts == TRUE){
    df <- filter(df,df$is_retweet == FALSE)
  }
  
  # Select the features that you want to keep from the Twitter stream and rename them
  # so the names match those of the columns in the Tweet_Data table in our database
  
  columnas <- c("user_id","status_id","created_at","screen_name","text","reply_to_status_id",
                "source","reply_to_screen_name","is_retweet","is_quote",
                "favorite_count","retweet_count","quote_count","reply_count",
                "retweet_screen_name",
                "description","followers_count","friends_count","statuses_count",
                "favourites_count","account_created_at")
  small_df <- df[,columnas]
  
  #names(small_df) <- c("User","Tweet_Content","Date_Created")
  # Finally normalize the tweet text
  small_df$text_cleaned <- sapply(small_df$text, limpiar)
  # Return the processed data frame
  
  small_df$lugar <- lugar
  
  return(small_df)
}