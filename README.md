
# Script de Création d'Utilisateur avec LVM et Quotas
# MASSE MASSE Paul-Basthylle

## Introduction

Ce script permet de:
- créer un utilisateur sur un système Linux lui attribuant un mdp par defaut
- Forcer l'user à changer son mdp a la première connexion
- Connecter un etudiant qui verifie d'abord si cet user respecte la plage d'heures qui lui est attribuée sinon il ne pourra pas se connecter
- attribuer un espace disque limité à l'aide de LVM (Logical Volume Manager).
- D'afficher la liste des users du groupe spécifique
- D'afficher la liste des users de mon (s)

- d'ajouter ce dernier à un groupe spécifique, et de lui  Le script crée également un répertoire de volume logique pour chaque utilisateur, offrant ainsi une gestion de l'espace disque de manière flexible et évolutive.

En faite, le groupe spécifique permet d'ajouter directement les users ayant des restrictions afin que ce celà n'est pas un autre impact sur mes autres comptes

## Prérequis

Avant d'exécuter ce script, assurez-vous que votre système est configuré avec LVM et dispose d'un disque ou d'une partition non utilisée pour créer des volumes physiques. Si vous n'avez pas de volume physique ou de groupe de volumes, vous devrez d'abord les configurer.

### Prérequis logiciels

- **LVM2** : LVM doit être installé sur votre machine.
  - Pour installer LVM sur Ubuntu/Debian :
    ```bash
    sudo apt update
    sudo apt install lvm2
    ```

### Prérequis matériels

- Un disque dur ou une partition non utilisée pour créer un volume physique.
- Un volume physique (PV) et un groupe de volumes (VG) doivent être configurés.
commandes:

- lsblk // permet de lister les disques

volume physique : 
 - sudo wipefs -a /dev/sda6    /*pour effacer les données de sda6 et formater */
 - sudo pvcreate /dev/sda6     /*creation du nouveau volume */
 - sudo vgcreate users_vg /dev/sda6    /*creation du groupe de volume */


## Fonctionnement du Script

Le script fonctionne en plusieurs étapes :

1. **Création de l'utilisateur** :

   - Vérifie si l'utilisateur existe déjà.
   - Crée un groupe nommé `restreint` si nécessaire. "qui est associé à la fonction connectuser[...]"
   - Crée l'utilisateur et lui attribue un mot de passe par défaut.
   - Ajoute l'utilisateur au groupe `restreint`.
   - lui donne les droits sudo afin de changer le mdp

2. **Gestion du disque avec LVM** :

   - Crée un volume logique (LV) pour l'utilisateur dans le groupe de volumes `users_vg`.
   - Formate le volume avec le système de fichiers `ext4`.
   - Monte le volume logique sur le répertoire personnel de l'utilisateur.
   - Ajoute l'entrée dans `/etc/fstab` pour un montage persistant.

3. **Suppression de l'utilisateur** :
   - Supprime l'utilisateur et son répertoire personnel en toute sécurité.
   - Si un volume logique est associé à l'utilisateur, il peut être supprimé manuellement.

## Utilisation

### Connection user

Permet de connecter un user s'il est dans entre 08h et 18h


### Créer un utilisateur avec un espace disque limité et un mdp par defaut

```bash
option 1. execute la fonction connect_user
```

Exécutez le script suivant pour créer un utilisateur avec un espace disque limité :

```bash
option 2. execute la fonction create_user
```

- **`nom_utilisateur`** : Le nom de l'utilisateur à créer.
- **`quota_disque`** : La taille de l'espace disque attribué à l'utilisateur (par exemple, `2G` pour 2 Go).
- **`ajout dans le groupe restreint`**

### Affichage des users du groupe restreint
```bash
option 3. 
```
### Affichage des users de ma machine
```bash
option 4. 
```

### Supprimer un utilisateur
```bash
option 5.supprimer_user() 
```

Pour supprimer un utilisateur et son répertoire associé, exécutez la commande suivante :


### Vérification des volumes LVM

Après avoir exécuté le script, vous pouvez vérifier les groupes de volumes et les volumes logiques créés avec les commandes suivantes :

- **Afficher les groupes de volumes** :
  ```bash
  sudo vgdisplay
  ```

- **Afficher les volumes logiques** :
  ```bash
  sudo lvdisplay
  ```



## Erreurs courantes

- **"Le groupe de volumes `users_vg` n'existe pas"** : Si le groupe de volumes LVM n'existe pas, vous devrez le créer avant d'exécuter le script. Utilisez la commande suivante pour créer le groupe de volumes :
  ```bash
  sudo vgcreate users_vg /dev/sdX
  ```
  Remplacez `/dev/sdX` par le disque ou la partition de votre choix.

- **"La partition est montée"** : Si une partition est utilisée, vous devez la démonter avant de pouvoir l'utiliser pour LVM. Utilisez la commande suivante :
  ```bash
  sudo umount /dev/sda6
  ```

---

