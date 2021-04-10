# Import necessary libraries and functions
library(RSQLite)
library(rtweet)
library(tm)
library(dplyr)
library(knitr)
library(lubridate)
library(ggplot2)
library(RMariaDB)
library(tidyverse)
library(DBI)

######## Parte I: relacionado a la base de datos MySQL ########

# Configuraciones
db_user <- 'root'
db_password <- 'root'
db_name <- 'pln'
db_host <- '127.0.0.1' # for local access
db_port <- 3306

# Conexion
con <- DBI::dbConnect(odbc::odbc(),
                      driver   = "MySQL ODBC 8.0 ANSI Driver",
                      database = db_name,
                      UID      = db_user,
                      PWD      = db_password,
                      host     = db_host,
                      port     = db_port,
                      encoding = 'utf8')

# Script de creacion de la tabla que almacenará los campos seleccionados
# para el estudio.
dbExecute(con, "CREATE TABLE cultura(
                      user_id TEXT,
                      status_id TEXT,
                      created_at DATETIME,
                      screen_name TEXT,
                      text TEXT CHARSET utf8,
                      reply_to_status_id TEXT,
                      source TEXT,
                      reply_to_screen_name TEXT,
                      is_retweet TEXT,
                      is_quote TEXT,
                      favorite_count INTEGER,
                      retweet_count INTEGER,
                      quote_count INTEGER,
                      reply_count INTEGER,
                      hashtags TEXT,
                      mentions_screen_name TEXT,
                      retweet_screen_name TEXT,
                      description TEXT,
                      followers_count INTEGER,
                      friends_count INTEGER,
                      statuses_count INTEGER,
                      favourites_count INTEGER,
                      account_created_at DATETIME,
                      text_cleaned TEXT,
                      lugar TEXT) ENGINE=InnoDB DEFAULT CHARSET=utf8;")

######## Parte II: relacionado con la conexion a Twitter ########

# llaves y tokens
consumer_key = '3V9zaJLQfHUuzPeS9xxpQIqxB'
consumer_secret = 'EjmT416EaPM3ol4ua9P4SRJLNHxLYOe7qNzUySAeTrY8zdieOF'
access_token = '1093529821861171206-WBsKJHO5dPww8mcZVbQxub4628pZPh'
access_secret = 'rztI9QiKRGSe6W0bWFQMnFs5zVPB42Ux6wN1VvtyjZ2Vw'

# conectar a la aplicacion (developer twitter)
token <- create_token(
  app = "TestPLN",
  consumer_key = consumer_key,
  consumer_secret = consumer_secret,
  access_token = access_token,
  access_secret = access_secret)

######## Parte III: recoleccion de tweets ########
source("limpiarDataFrame.R")

# Parametros de la busqueda
# Flitramos a personas que hayan hablado o hablen sobre el tema de la cultura
# digital y su principal tema relacionao. Se incluye a toda Latinoamérica, la
# cual incluye Brasil y por ende habrá que manejar dos idiomas en algunas secciones.
consulta = "\"cultura digital\" OR \"transformación digital\" OR \"transformacion digital\" OR \"transformação digital\" OR \"transformacao digital\""
cantidad = 5000

# Geocodes para latinoamérica #
countries = list(
                c("el_salvador" , "13.69,-89.19,35mi"),
                c("guatemala" , "14.96,-90.77,75mi"),
                c("honduras" , "15.10,-87.02,90mi"),
                c("nicaragua" , "12.13,-86.24,80mi"),
                c("costa_rica" , "9.94,-84.10,80mi"),
                c("panama" , "8.82,-80.27,160mi"),
                c("mexico" , "19.44,-99.10,530mi"),
                c("colombia" , "3.88,-73.11,250mi"),
                c("ecuador" , "-1.22,-78.39,160mi"),
                c("venezuela" , "7.53,-64.72,200mi"),
                c("peru" , "-11.07,-75.54,400mi"),
                c("bolivia" , "-17.06,-64.44,330mi"),
                c("brazil" , "-12.01,-48.70,777mi"),
                c("paraguay" , "-25.47,-56.07,100mi"),
                c("uruguay" , "-32.96,-55.65,140mi"),
                c("argentina" , "-34.58,-64.21,310mi"),
                c("chile" , "-33.48,-70.83,60mi") #partial
            )

# Recoleccion de la informacion
for(index in 1:length(countries)){
    print(index)
    country = countries[[index]]
    r <- tryCatch(search_tweets2(q = consulta, 
                                 n = cantidad, 
                                 include_rts=TRUE,
                                 geocode=country[2],
                                 #max_id=minimo,
                                 retryonratelimit = TRUE,
                                 lang="es"),
                  error = function(e) return(NULL))
    
    if(length(r)!=0){
        # Convertir la fecha a hora local de El Salvador
        conglomerado <- r %>% 
          mutate(created_at = with_tz(created_at, tz = "America/El_Salvador") )
        
        # Limpiar y guardar en la base de datos
        clean_stream <- transform_and_clean_tweets(conglomerado, remove_rts = FALSE, country[1])
        dbWriteTable(con, "cultura",clean_stream,append=TRUE,encoding = "utf8")
    }
}

# Guardar en archivo RDS
datos <- dbGetQuery(con, "SELECT * FROM pln.cultura",encoding = "utf8")
saveRDS(datos, "conglomerado.rds")

# Nos desconectamos de la base de datos
dbDisconnect(con)
