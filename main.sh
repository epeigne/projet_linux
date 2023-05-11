#!/bin/bash

#add test
# Définir le chemin d'accès du fichier CSV
csv_file="accounts.csv"

# Lire le fichier CSV ligne par ligne et le traiter avec awk
awk -F ';' 'NR>1 { print $1}' "$csv_file">name.txt
awk -F ';' 'NR>1 { print $2}' "$csv_file">surname.txt
awk -F ';' 'NR>1 { print $3}' "$csv_file">mail.txt
awk -F ';' 'NR>1 { print $4}' "$csv_file">password.txt

#creation variables data user (1ere personne pour l'instant)
name= sed -n '1p' name.txt
surname= sed -n '1p' surname.txt
mail= sed -n '1p' mail.txt
passwd= sed -n '1p' password.txt

#print de verif
echo $name $surname $mail $passwd
