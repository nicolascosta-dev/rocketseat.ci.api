# ==========================================
# Etapa 1: Build (Ambiente de compilação)
# ==========================================
FROM node:18-alpine AS build
WORKDIR /usr/src/app

# Copia absolutamente todos os arquivos do projeto para o container
COPY . .

# Instala todas as dependências (incluindo as de desenvolvimento)
RUN npm install

# Executa o script de build da aplicação
RUN npm run build

# Remove as dependências de dev de todos os workspaces de forma nativa e limpa o cache
ENV NODE_ENV=production
RUN npm prune && npm cache clean --force


# ==========================================
# Etapa 2: Production (Imagem final leve)
# ==========================================
FROM node:18-alpine AS production
WORKDIR /usr/src/app

# Define o ambiente como produção também na imagem final
ENV NODE_ENV=production

# Copia apenas os artefatos gerados no build e as dependências de produção já filtradas
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package*.json ./

# Copia a estrutura limpa dos workspaces para o Node encontrar os pacotes locais
COPY --from=build /usr/src/app/ . 

# Expõe a porta 3000
EXPOSE 3000

# Inicia a aplicação em produção
CMD ["npm", "run", "start:prod"]
