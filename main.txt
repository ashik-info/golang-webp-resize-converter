package main

import (
	"bytes"
	"fmt"
	"image"
	"image/draw"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/HugoSmits86/nativewebp"
	"github.com/disintegration/imaging"
	"github.com/gofiber/fiber/v2"
)

func main() {
	app := fiber.New()

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
		img, _, err := image.Decode(file)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).SendString("invalid image format")
		}
		wStr := c.FormValue("width", "0")
		hStr := c.FormValue("height", "0")
		w, _ := strconv.Atoi(wStr)
		h, _ := strconv.Atoi(hStr)
		if w <= 0 && h <= 0 {
			w = img.Bounds().Dx()
			h = img.Bounds().Dy()
		}
		resized := imaging.Resize(img, w, h, imaging.Lanczos)
		rgba := toRGBA(resized)
		var buf bytes.Buffer
		err = nativewebp.Encode(&buf, rgba, nil)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).SendString("WebP encoding failed")
		}
		filename := fmt.Sprintf("converted-%d.webp", time.Now().UnixNano())
		saveDir := "./files"
		savePath := filepath.Join(saveDir, filename)

		if err := os.MkdirAll(saveDir, os.ModePerm); err != nil {
			return c.Status(500).SendString("failed to create output directory")
		}
		if err := os.WriteFile(savePath, buf.Bytes(), 0644); err != nil {
			return c.Status(500).SendString("failed to save WebP file")
		}
		c.Set("Content-Type", "image/webp")
		c.Set("Content-Disposition", `attachment; filename="converted.webp"`)
		return c.Send(buf.Bytes())
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}
	log.Println("🚀 Listening on http://localhost:" + port)
	log.Fatal(app.Listen(":" + port))
}

// toRGBA converts any image.Image to *image.RGBA
func toRGBA(img image.Image) *image.RGBA {
	rgba := image.NewRGBA(img.Bounds())
	draw.Draw(rgba, rgba.Bounds(), img, image.Point{}, draw.Src)
	return rgba
}
