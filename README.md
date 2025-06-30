## Efficient Image Conversion to WebP Using Go and Fiber

The WebP image format, developed by Google, offers significant compression and quality advantages over traditional formats such as PNG and JPEG. Implementing a seamless conversion to WebP can greatly optimize storage and improve web performance. In this article, we'll walk through an efficient Go application using the Fiber framework to convert images to WebP.

Setting up the Go Environment

First, ensure you have Go installed and set up the Fiber framework:

```.sh
go get github.com/gofiber/fiber/v2
go get github.com/HugoSmits86/nativewebp
go get github.com/disintegration/imaging
```
### Application Overview

The provided Go script efficiently handles file uploads, processes images, and returns WebP-encoded files. Let's dive into the main components:

Creating a Fiber Web Server

Fiber provides a lightweight yet powerful framework to handle HTTP requests effortlessly:

```.go
app := fiber.New()
```
Handling File Uploads

The application includes an endpoint /convert which handles POST requests to upload and convert images:

```.go
app.Post("/convert", func(c *fiber.Ctx) error {
	fileHeader, err := c.FormFile("file")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).SendString("`file` field required")
	}

	file, err := fileHeader.Open()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).SendString("cannot open uploaded file")
	}
	defer file.Close()
```
Decoding and Resizing Images

The uploaded image file is decoded and optionally resized based on user input parameters (width and height):
```.go
img, _, err := image.Decode(file)
if err != nil {
	return c.Status(fiber.StatusBadRequest).SendString("invalid image format")
}

w, _ := strconv.Atoi(c.FormValue("width", "0"))
h, _ := strconv.Atoi(c.FormValue("height", "0"))

if w <= 0 && h <= 0 {
	w = img.Bounds().Dx()
	h = img.Bounds().Dy()
}

resized := imaging.Resize(img, w, h, imaging.Lanczos)
```
Converting Images to RGBA Format

WebP encoding requires an RGBA image. The provided helper function toRGBA() ensures compatibility:
```.go
func toRGBA(img image.Image) *image.RGBA {
	rgba := image.NewRGBA(img.Bounds())
	draw.Draw(rgba, rgba.Bounds(), img, image.Point{}, draw.Src)
	return rgba
}
```
Encoding to WebP

The RGBA image is then encoded into WebP format using the nativewebp library:
```.go
var buf bytes.Buffer
err = nativewebp.Encode(&buf, rgba, nil)
if err != nil {
	return c.Status(fiber.StatusInternalServerError).SendString("WebP encoding failed")
}
```
Saving the WebP File

The encoded WebP file is saved to the server’s file system:
```.go
filename := fmt.Sprintf("converted-%d.webp", time.Now().UnixNano())
saveDir := "./files"
os.MkdirAll(saveDir, os.ModePerm)
os.WriteFile(filepath.Join(saveDir, filename), buf.Bytes(), 0644)
```
Sending the WebP File as a Response

The converted file is immediately returned to the client with appropriate headers for downloading:
```.go
c.Set("Content-Type", "image/webp")
c.Set("Content-Disposition", `attachment; filename="converted.webp"`)
return c.Send(buf.Bytes())
```
Running the Application

The server listens on port 3000 (configurable through the PORT environment variable):
```.sh
go run main.go
```
