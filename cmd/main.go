package main

import (
	"log"
	"ross146/todo-app"
	"ross146/todo-app/pkg/handler"
	"ross146/todo-app/pkg/repository"
	"ross146/todo-app/pkg/service"
)

func main() {
	repos := repository.NewRepository()
	services := service.NewService(repos)
	handlers := handler.NewHandler(services)

	srv := new(todo.Server)
	if err := srv.Run("8000", handlers.InitRoutes()); err != nil {
		log.Fatal(err)
	}
}
