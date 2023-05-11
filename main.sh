#!/bin/bash


# Définir le chemin d'accès du fichier CSV
csv_file="accounts.csv"

# Lire le fichier CSV ligne par ligne et le traiter avec awk
awk -F ';' 'NR>1 { print $1}' "$csv_file">name.txt
awk -F ';' 'NR>1 { print $2}' "$csv_file">surname.txt
awk -F ';' 'NR>1 { print $3}' "$csv_file">mail.txt
awk -F ';' 'NR>1 { print $4}' "$csv_file">password.txt

#creation variables data user (1ere personne pour l'instant)
name=$(awk 'NR==1{print $1}' name.txt)
surname=$(awk 'NR==1{print $1}' surname.txt)
mail=$(awk 'NR==1{print $1}' mail.txt)
passwd=$(awk 'NR==1{print $1}' password.txt)

#print de verif
#echo $name $surname $mail $passwd

#afficher premiere lettre du prenom et creer username en minuscule
first_letter=${name:0:1}
username=$(echo $first_letter$surname | tr '[:upper:]' '[:lower:]')

#creation user avec adduser et set passwd
sudo useradd $username
echo $username:$passwd | sudo chpasswd

#expiration du mot de passe
sudo chage --lastday 0 $username

#creation du home
sudo mkdir /home/$username
sudo chown $username:$username /home/$username





