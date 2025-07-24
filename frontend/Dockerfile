FROM node:18 as build
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:18 as serve
WORKDIR /usr/src/app
COPY --from=build /usr/src/app/build ./build
COPY public/config.js.template ./build/config.js
COPY entrypoint.sh /entrypoint.sh
RUN npm install -g serve && chmod +x /entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["serve", "-s", "build"] 