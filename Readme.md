# Terraform AWS Multi-Tier Architecture

## Descrição

Este projeto demonstra como provisionar uma arquitetura de aplicação web de múltiplas camadas (Multi-Tier) na AWS utilizando Terraform. A infraestrutura inclui uma VPC customizada, sub-redes públicas e privadas, balanceador de carga (ALB), instâncias EC2 com auto scaling, e grupos de segurança (Security Groups).

## Estrutura da Arquitetura

A arquitetura provisionada inclui os seguintes componentes:

- **VPC**: Uma Virtual Private Cloud que isola a rede da aplicação.
- **Subnets**: Sub-redes públicas e privadas dentro da VPC.
- **Internet Gateway**: Para permitir acesso à internet das instâncias na subnet pública.
- **Route Tables**: Configuração das tabelas de roteamento para controlar o tráfego de rede.
- **Security Groups**: Grupos de segurança para controle de tráfego de entrada e saída.
- **EC2 Instances**: Instâncias de aplicação distribuídas em uma subnet privada, escaladas automaticamente.
- **Load Balancer (ALB)**: Um Application Load Balancer distribuindo o tráfego entre as instâncias EC2.

## Anotações
Atualmente esse Terraform esta dividido em duas parte
- A parte de web, por exemplo seria a parte onde colocaria o front-end de um site. Aqui seria onde configuramos o Load Balance para ter acesso web
- E a parte da logica, onde colocaria o back end, aqui seria onde ficaria a instancia de um ec2 onde ficaria a logica do programa e só acessaria internamente, por exemplo o SSH.

## Estudo Futuro
- Adicionar uma config de RDS
- Integracao de um S3 para fazer armazenamento de arquivos
- Fazer uma config de CI/CD
- Algum momento fazer um CloudWatch