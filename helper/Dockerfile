ARG base_image

# Builder: Build the Go app using an image with the Go toolchain installed.
FROM golang AS build
ADD . /app
WORKDIR /app
RUN go build .

# Create the final image based on our hardened base image.
FROM ${base_image}
COPY --from=build /app/helper /app/

CMD [ "helper" ]
