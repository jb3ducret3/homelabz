#!/bin/bash
# Script de création automatique d'une VM OMV sur Proxmox

# 📌 Variables de base
VMID=110  # Identifiant unique de la VM
VM_NAME="omv-nas"
ISO_STORAGE="local"      # Stockage ISO (généralement 'local')
DISK_STORAGE="local-lvm" # Stockage pour les disques (ex: 'local-lvm')
DISK_SIZE="50G"          # Taille des disques pour le RAID
MAIN_DISK_SIZE="20G"     # Taille du disque principal (OS)
ISO_NAME="openmediavault_7.4.17-amd64.iso"
ISO_PATH="/var/lib/vz/template/iso/$ISO_NAME"

# 📌 Vérification et téléchargement de l'ISO si absent
if [ ! -f "$ISO_PATH" ]; then
    echo "🔽 Téléchargement de l'ISO OpenMediaVault..."
    wget -P /var/lib/vz/template/iso/ "https://downloads.sourceforge.net/project/openmediavault/7.4.17/openmediavault_7.4.17-amd64.iso"
else
    echo "✅ ISO déjà présent : $ISO_PATH"
fi

# 📌 Demande à l'utilisateur les noms des volumes
read -p "Entrez le nom du volume virtuel pour le disque 1 (exemple : disk-1) : " DISK1_NAME
read -p "Entrez le nom du volume virtuel pour le disque 2 (exemple : disk-2) : " DISK2_NAME

echo "🚀 Création de la VM $VM_NAME (ID: $VMID)..."
qm create $VMID --name "$VM_NAME" --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0

echo "🔧 Configuration du matériel de la VM..."
qm set $VMID --scsihw virtio-scsi-pci

echo "📀 Attachement de l'ISO OMV..."
qm set $VMID --ide2 ${ISO_STORAGE}:iso/${ISO_NAME},media=cdrom

echo "💾 Création du disque principal (OS) de $MAIN_DISK_SIZE..."
qm disk create $VMID scsi0 --storage $DISK_STORAGE --size $MAIN_DISK_SIZE
qm set $VMID --boot c --bootdisk scsi0

echo "📀 Création et attachement du disque 1 ($DISK_SIZE)..."
pvesm alloc $DISK_STORAGE $VMID $DISK1_NAME $DISK_SIZE --format raw
qm set $VMID --scsi1 ${DISK_STORAGE}:$DISK1_NAME

echo "📀 Création et attachement du disque 2 ($DISK_SIZE)..."
pvesm alloc $DISK_STORAGE $VMID $DISK2_NAME $DISK_SIZE --format raw
qm set $VMID --scsi2 ${DISK_STORAGE}:$DISK2_NAME

echo "🔍 Vérification de la configuration..."
qm config $VMID

echo "✅ La VM $VM_NAME (ID: $VMID) a été créée avec succès !"
echo "Pour démarrer la VM, utilisez : qm start $VMID"
