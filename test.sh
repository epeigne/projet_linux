#!/bin/bash

#add test
# Définir le chemin d'accès du fichier CSV
csv_file="accounts.csv"

# Lire le fichier CSV ligne par ligne et le traiter avec awk
awk -F ';' '{ print "Username: " $1 ",\nSurname: " $2 ",\nMail: " $3 ",\nPassword: " $4 "\n" }' "$csv_file"

# Lire une ligne spécifique du fichier CSV
sed -n '2p' "$csv_file"
