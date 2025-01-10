#!/bin/bash

# Tarkista, että openssl on asennettu
if ! command -v openssl &>/dev/null; then
    echo "Error: openssl is not installed. Please install openssl and try again."
    exit 1
fi

# Valitse kieli (oletuskieli: englanti)
default_language="en"
read -p "Select language / Valitse kieli (en/su): [en] " LANGUAGE
LANGUAGE=${LANGUAGE:-$default_language}

# Tarkista, onko valittu kieli tuettu
if [[ "$LANGUAGE" != "en" && "$LANGUAGE" != "su" ]]; then
    echo "Invalid language selection. Defaulting to English."
    LANGUAGE="en"
fi

# Funktio viestien näyttämiseen
function translate() {
    local en_message="$1"
    local su_message="$2"
    if [[ "$LANGUAGE" == "su" ]]; then
        echo "$su_message"
    else
        echo "$en_message"
    fi
}

# Kysy asiakkaan nimi
translate "Enter the client name (no spaces): " "Anna asiakkaan nimi (ilman välilyöntejä): "
read CLIENT_NAME

# Tarkista, että nimi ei ole tyhjä
if [[ -z "$CLIENT_NAME" ]]; then
    translate "Error: Client name is required." "Virhe: Asiakkaan nimi on pakollinen."
    exit 1
fi

# Luodaan kansio asiakkaalle
CERT_DIR="./certificates/$CLIENT_NAME"
mkdir -p "$CERT_DIR"

translate "Creating certificates for client: $CLIENT_NAME" "Luodaan sertifikaatit asiakkaalle: $CLIENT_NAME"

# 1. Luo juurisertifikaatin yksityinen avain
ROOT_KEY="$CERT_DIR/${CLIENT_NAME}-root-ca.key"
ROOT_CERT="$CERT_DIR/${CLIENT_NAME}-root-ca.pem"
openssl genrsa -out "$ROOT_KEY" 2048

# 2. Luo juurisertifikaatti
openssl req -x509 -new -nodes -key "$ROOT_KEY" -sha256 -days 730 -out "$ROOT_CERT" -subj "/CN=${CLIENT_NAME}-root-ca"

translate "Root certificate created: $ROOT_CERT" "Juurisertifikaatti luotu: $ROOT_CERT"

# 3. Luo asiakassertifikaatin yksityinen avain
CLIENT_KEY="$CERT_DIR/${CLIENT_NAME}-client.key"
CLIENT_CSR="$CERT_DIR/${CLIENT_NAME}-client.csr"
CLIENT_CERT="$CERT_DIR/${CLIENT_NAME}-client.pem"
openssl genrsa -out "$CLIENT_KEY" 2048

# 4. Luo allekirjoituspyyntö (CSR) asiakassertifikaatille
openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -subj "/CN=${CLIENT_NAME}-client-cert"

# 5. Allekirjoita asiakassertifikaatti juurisertifikaatilla
openssl x509 -req -in "$CLIENT_CSR" -CA "$ROOT_CERT" -CAkey "$ROOT_KEY" -CAcreateserial -out "$CLIENT_CERT" -days 548 -sha256

translate "Client certificate created: $CLIENT_CERT" "Asiakassertifikaatti luotu: $CLIENT_CERT"

# 6. Näytä lopputulos
translate "Certificates for client $CLIENT_NAME created in folder: $CERT_DIR" \
          "Sertifikaatit asiakkaalle $CLIENT_NAME luotu kansioon: $CERT_DIR"
translate "Deliverable file to the counterparty: $ROOT_CERT" \
          "Toimitettava tiedosto vastaosapuolelle: $ROOT_CERT"
