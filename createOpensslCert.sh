#!/bin/bash

name=
pos_algorithms="RSA|ED25519"
algorithm=ED25519
bits=4096
convert=0
days=365
help=0
usage=0


function printUsage() {
    echo "Usage: $0 -n <name> [-a=<${pos_algorithms}>] [-b=<bits>] [-d <days>] [-c] [-h]"
    return 0;
}

function printHelp() {
    printUsage
    echo ""
    echo "-n Name of the cert"
    echo "-a Algorithm: RSA|ED25519. Default: ED25519"
    echo "-b Bits for RSA. Default: 4096"
    echo "-d Days the certificate is valid. Default: 365"
    echo "-c Additionally convert to .der"
    echo "-h Print this."
    return 0;
}

while (("$#")); do
    case "$1" in
        -a | --algorithm)
            algorithm=$2
            shift 2
            ;;
        -d | --days)
            days=$2
            shift 2
            ;;
        -b | --bits)
            bits=$2
            shift 2
            ;;
        -c | --convert)
            convert=1
            shift 1
            ;;
        -n | --name)
            name=$2
            shift 2
            ;;
        -h | --help)
            help=1
            break
            ;;
        -* | --usage)
            usage=1
            break
            ;;
        *) # No more options
            break
            ;;
    esac
done


if [[ ${usage} == 1 ]]; then
    printUsage
    exit $?
fi

if [[ ${help} == 1 ]]; then
    printHelp
    exit $?
fi

if [[ ${name} == "" ]]; then
    echo [e] No name given!
    echo 
    printHelp
    exit $?
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"


echo "name: "${name}
echo "algorithm: "${algorithm}
echo "bits: "${bits}

priv_key=${name}.priv.pem
pub_key=${name}.pub.pem
pem_cert=${name}.cert.pem
pfx_cert=${name}.pfx

# gen private key
echo "generating private key"
if [[ ${algorithm} == "RSA" || ${algorithm} == "rsa" ]]; then 
    openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:${bits} -outform pem -out ${priv_key}
fi
if [[ ${algorithm} == "ED25519" || ${algorithm} == "ed25519" ]]; then 
    openssl genpkey -algorithm ED25519 -outform pem -out ${priv_key}
fi

# gen pub key
echo "generating public key"
openssl pkey -in ${priv_key} -pubout -out ${pub_key}


# create a self-signed certificate using that key
echo "generating self signed certificate"
if [[ $key > 0 ]]; then
    openssl req -new -x509 -key ${priv_key} -out ${pem_cert} -days ${days}
else
    openssl req -new -x509 -key ${priv_key} -out ${pem_cert}
fi

# convert pem to pfx
echo "converting pem to pfx"
openssl pkcs12 -export -inkey ${priv_key} -in ${pem_cert} -out ${pfx_cert}

if [[ ${convert} == 1 ]]; then 
    echo "converting pem to der"
    
    priv_der=${name}.priv.der
    pub_der=${name}.pub.der
    der_cert=${name}.cert.der
    
    openssl pkey -in ${priv_key} -outform der -out ${priv_der}
    openssl pkey -in ${priv_key} -pubout -outform der -out ${pub_der}
    # openssl rsa -inform pem -in ${priv_key} -outform der -out ${priv_der}
    # openssl rsa -pubin -inform pem -in ${pub_key} -outform der -out ${pub_der}
    openssl x509 -outform der -in ${pem_cert} -out ${der_cert}
fi

exit $?
