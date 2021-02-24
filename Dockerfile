### STAGE 1: Build ###
# We label our stage as ‘builder’
FROM amd64/node:15-alpine as builder
WORKDIR /ng-app
COPY package*.json ./
COPY .npmrc .
## Storing node modules on a separate layer will prevent unnecessary npm installs at each build
RUN npm ci
COPY . .
## Build the angular app in production mode and store the artifacts in dist folder
RUN npm run ng build -- --prod --output-path=dist
### STAGE 2: Setup ###
FROM amd64/nginx
## Copy our default nginx config
COPY nginx/default.conf /etc/nginx/conf.d/configfile.template
## Update port in default.conf
ENV PORT 8080
## Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*
## From ‘builder’ stage copy over the artifacts in dist folder to default nginx public folder
COPY --from=builder /ng-app/dist /usr/share/nginx/html
CMD sh -c "envsubst '\$PORT' < /etc/nginx/conf.d/configfile.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
