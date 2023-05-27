#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------PARAMETRES-----------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

echo "--------------------------------------------------"
echo "--------ATTENTION AU FORMAT DU MAIL DU CSV--------"
echo "--------------------------------------------------"

# Demander à l'utilisateur de saisir les paramètres mail
echo "Veuillez entrer une adresse smtp :"
read smtpaddress
echo "Veuillez entrer un port smtp :"
read smtpport
echo "Veuillez entrer un login (mail pour le serveur smtp) :"
read userlogin
echo "Veuillez entrer un mot de passe (attention aux caractères spéciaux) :"
read userpass
smtpserv=$smtpaddress":"$smtpport
#echo $smtpserv

# Définir le chemin d'accès du fichier CSV
csv_file="accounts.csv"


#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------LECTURE CSV----------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

# Lire le fichier CSV ligne par ligne et le traiter avec awk
awk -F ';' 'NR>1 { print $1}' "$csv_file">name.txt
awk -F ';' 'NR>1 { print $2}' "$csv_file">surname.txt
awk -F ';' 'NR>1 { print $3}' "$csv_file">mail.txt
awk -F ';' 'NR>1 { print $4}' "$csv_file">password.txt

#avoir le nombre de lignes du csv pour la boucle for de creation des users
nb_lignes=$(wc -l < $csv_file)

#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------ECLIPSE--------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

#telechargement eclipse et deplacement dans /opt
wget --directory-prefix=/opt/ https://ftp.fau.de/eclipse/technology/epp/downloads/release/2023-03/R/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz && tar xzvf /opt/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz -C "/opt/" eclipse && chown -R root:root /opt/eclipse/ 


#ajout droit execution pour tous le monde
chmod a+x /opt/eclipse/eclipse

#creation lien symbolique vers ecplise
ln -s /opt/eclipse/eclipse /usr/local/bin/eclipse

#suppression du tar
rm -f /opt/eclipse-java-2023-03-R-linux-gtk-x86_64.tar.gz


#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------PARE-FEU-------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

#verifie si ufw est installé
if [ ! -f /usr/sbin/ufw ]
then
    apt install ufw
fi

#bloque les connexions ftp
ufw deny ftp

#bloque les connexions udp
ufw deny proto udp from any to any

#active le pare-feu
ufw enable

#affichage des regles (uncomment pour afficher les regles si besoin)
# echo "--------------------------------------------------"
# echo "-------------------REGLES UFW---------------------"
# echo "--------------------------------------------------"
# ufw status verbose
# echo "--------------------------------------------------"


#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------NEXTCLOUD------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

#preinstallation de nextcloud grace a un repo externe et nextcloud-server
#lien vers le repo externe: https://git.jurisic.org/ijurisic/nextcloud-deb
ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "wget -qO - https://apt.jurisic.org/Release.key | gpg --dearmor | sudo dd of=/usr/share/keyrings/jurisic-keyring.gpg"
ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "echo \"deb [ signed-by=/usr/share/keyrings/jurisic-keyring.gpg ] https://apt.jurisic.org/debian/ $(lsb_release -cs) main contrib non-free\" | sudo tee /etc/apt/sources.list.d/jurisic.list" 
ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "sudo apt update && sudo apt install nextcloud-server"

#installation du serveur nextcloud avec occ et creation du compte admin
ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "cd /usr/sbin/occ && occ maintenance:install --admin-user=\"nextcloud-admin\" --admin-pass=\"N3x+_Cl0uD\""


#-----------------------------------------------------------------------------------------------------------------
#--------------------------------------------------CREATION USER--------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------

for((i=1;i<=$nb_lignes;i++));
do

    #creation variables data user

    name=$(awk -v line="$i" 'NR==line{print $1}' name.txt)
    surname=$(awk -v line="$i" 'NR==line{print $1}' surname.txt)
    mail=$(awk -v line="$i" 'NR==line{print $1}' mail.txt)
    passwd=$(awk -v line="$i" 'NR==line{print $1}' password.txt)

    #print de verif
    #echo $name $surname $mail $passwd

    #afficher premiere lettre du prenom et creer username en minuscule
    first_letter=${name:0:1}
    username=$(echo $first_letter$surname | tr '[:upper:]' '[:lower:]')

    #creation user avec adduser et set passwd
    useradd -s /bin/bash -m $username
    echo $username:$passwd | chpasswd

    #expiration du mot de passe
    chage --lastday 0 $username

    #creation dossier sauvegarde 
    mkdir /home/$username/a_sauver

    #creation dossier shared si il n'existe pas
    if [ ! -d /home/shared ]
    then
        mkdir /home/shared
        chown root:root /home/shared
        chmod 775 /home/shared
    fi

    #creation dossier user dans shared
    if [ ! -d /home/shared/$username ]
    then
        mkdir /home/shared/$username
        chown $username:$username /home/shared/$username
        chmod 755 /home/shared/$username
    fi


    #-----------------------------------------------------------------------------------------------------------------
    #--------------------------------------------------NEXTCLOUD------------------------------------------------------
    #-----------------------------------------------------------------------------------------------------------------

    #creation du compte nextcloud de l'utilisateur
    export OC_PASS=$passwd
    ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "su -s /bin/sh www-data -c \"php occ user:add --password-from-env --display-name=\"$name $surname\" $username\""




    #-----------------------------------------------------------------------------------------------------------------
    #--------------------------------------------------ENVOI DE MAIL--------------------------------------------------
    #-----------------------------------------------------------------------------------------------------------------

    #remplacement de @ par %40 pour l'envoi du mail
    userlogin_smtp=$(echo $userlogin | sed 's/@/%40/g')

    ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "echo -e \"Bonjour $name $surname,\n\nVous trouverez ci-joint vos identifiants:\nUsername: $username\nPassword: $passwd\n\nAttention: vous devrez changer votre mot de passe lors de votre première connexion!\" | mail --subject \"Création compte Linux\" --exec \"set sendmail=smtp://$userlogin_smtp:$userpass;auth=LOGIN@$smtpserv\" --append "From:$userlogin" $mail"


    #-----------------------------------------------------------------------------------------------------------------
    #--------------------------------------------------SAUVEGARDE-----------------------------------------------------
    #-----------------------------------------------------------------------------------------------------------------

    #creation dossier saves sur serveur de sauvegarde
    ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "mkdir -p /home/saves"
    ssh -i /root/.ssh/id_rsa epeign25@10.30.48.100 "chmod 666 /home/saves"

    #creation crontab pour sauvegarde automatique
    crontab -l > /tmp/crontab.tmp
    echo "*/2 * * * * tar -czf /home/$username/save_$username.tgz -C \"/home/$username/\" a_sauver/ && chmod a+x /home/$username/save_$username.tgz && scp -i /root/.ssh/id_rsa /home/$username/save_$username.tgz epeign25@10.30.48.100:/home/saves && rm -f /home/$username/save_$username.tgz" >> /tmp/crontab.tmp
    crontab /tmp/crontab.tmp
    rm /tmp/crontab.tmp

    #recuperation sauvegarde
    echo "scp -i /root/.ssh/id_rsa epeign25@10.30.48.100:/home/saves/save_$username.tgz /home/$username &&  tar -xzf /home/$username/save_$username.tgz -C "/home/$username" && rm -f /home/$username/save_$username.tgz" > /home/$username/retablir_sauvegarde.sh
    chmod a+x /home/$username/retablir_sauvegarde.sh

done