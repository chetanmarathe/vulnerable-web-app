FROM node:14

WORKDIR /app

# Upgrade npm to version 7.21.0
RUN npm install -g npm@7.21.0

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
