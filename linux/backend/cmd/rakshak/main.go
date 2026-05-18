package main

import (
	"log"
	"os"

	"github.com/rakshak/rakshak/internal/config"
	"github.com/rakshak/rakshak/internal/server"
	"github.com/rakshak/rakshak/internal/worker"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	switch os.Getenv("RAKSHAK_MODE") {
	case "worker":
		if err := worker.Run(cfg); err != nil {
			log.Fatal(err)
		}
	default:
		if len(os.Args) > 1 && os.Args[1] == "worker" {
			if err := worker.Run(cfg); err != nil {
				log.Fatal(err)
			}
			return
		}
		if err := server.Run(cfg); err != nil {
			log.Fatal(err)
		}
	}
}
