workspace {
    name "Домашнее задание 1"

    !identifiers hierarchical

    !docs documentation
    !adrs decisions

    model {

        properties { 
            structurizr.groupSeparator "/"
        }

        user = person "Пользователь"
        yandex_system = softwareSystem "API Яндекс карт" {
            description "Или что-то иное..."
        }

        main_system = softwareSystem "Приложение 'Попутчик'" {
            description "Позволяет заносить информацию о поездках и марщрутах для последующего поиска других пользователей со схожими параметрами"
            
            gateway = container "Общий интерфейс" {
                description "Предоставляет единый доступ к другим сервисам, отправляя нужные запросы им"
            }
            
            user_service = container "Сервис пользователей" {
                description "Управляет пользователями"
            }

            path_service = container "Сервис маршрутов" {
                description "Управляет маршрутами"
            }

            trip_service = container "Сервис поездок" {
                description "Управляет поездками"
            }

            group "Слой данных" {
                user_db = container "User DB" {
                    description "База данных с пользователями"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                user_cache = container "User Cache" {
                    description "Кеш пользовательских данных для ускорения аутентификации"
                    technology "PostgreSQL 15"
                    tags "database"
                }

                poput_db = container "'Poputchik' DB" {
                    description "База данных для хранения информации о поездках и маршрутах"
                    technology "MongoDB 5"
                    tags "database"
                }
            }

            user -> gateway "Запрос" "REST HTTP:443"

            gateway -> user_service "Взаимодействие с пользователями" "TCP 7645"
            gateway -> path_service "Взаимодействие с маршрутами" "TCP 8694"
            gateway -> trip_service "Взаимодействие с поездками" "TCP 4879"

            trip_service -> path_service "Запрос маршрута"
            path_service -> yandex_system "Запрос на получение маршрута из точки А в точку Б" "REST HTTP:443"

            user_service -> user_cache "Получение/обновление данных о пользователях" "TCP 6379"
            user_service -> user_db "Получение/обновление данных о пользователях" "TCP 5432"

            path_service -> poput_db "Получение/обновление данных о маршрутах" "TCP 27018"
            trip_service -> poput_db "Получение/обновление данных о поездках" "TCP 27018"
        }

        deploymentEnvironment "Production" {

            deploymentNode "Gateway Server" {
                containerInstance main_system.gateway
            }

            deploymentNode "User Server" {
                containerInstance main_system.user_service
            }

            deploymentNode "Path Server" {
                containerInstance main_system.path_service
            }

            deploymentNode "Trip Server" {
                containerInstance main_system.trip_service
            }

            deploymentNode "databases" {
     
                deploymentNode "Database Server 1" {
                    containerInstance main_system.user_db
                }

                deploymentNode "Database Server 2" {
                    containerInstance main_system.poput_db
                    instances 3
                }

                deploymentNode "Cache Server" {
                    containerInstance main_system.user_cache
                }
            }
        }
    }

    views {
        themes default

        properties { 
            structurizr.tooltips true
        }

        !script groovy {
            workspace.views.createDefaultViews()
            workspace.views.views.findAll { it instanceof com.structurizr.view.ModelView }.each { it.enableAutomaticLayout() }
        }

        systemContext main_system "Context" {
            include *
            autoLayout
        }

        container main_system "Container" {
            include *
            autoLayout
        }

        deployment main_system "Production" "Deploy" {
            include *
            autoLayout
        }

        dynamic main_system "UC01" "Добавление нового пользователя" {
            autoLayout
            user -> main_system.gateway "Создать нового пользователя (POST /user)"
            main_system.gateway -> main_system.user_service "Создать нового пользователя"
            main_system.user_service -> main_system.user_db "Сохранить данные о пользователе" 
        }

        dynamic main_system "UC02" "Поиск пользователя по логину" {
            autoLayout
            user -> main_system.gateway "Поиск пользователя (GET /search/user?login=<str>)"
            main_system.gateway -> main_system.user_service "Поиск пользователя"
            main_system.user_service -> main_system.user_db "Получить данные о пользователе"
        }

        dynamic main_system "UC03" "Поиск пользователя по имени (фамилии)" {
            autoLayout
            user -> main_system.gateway "Поиск пользователя (GET /search/user?fname=<str>&sname=<str>)"
            main_system.gateway -> main_system.user_service "Поиск пользователя"
            main_system.user_service -> main_system.user_db "Получить данные о пользователе"
        }

        dynamic main_system "UC04" "Создание маршрута" {
            autoLayout
            user -> main_system.gateway "Создание маршрута (POST /path)"
            main_system.gateway -> main_system.path_service "Поиск пользователя"
            main_system.path_service -> yandex_system "Получить новый маршрут"
            main_system.path_service -> main_system.poput_db "Сохранить новый маршрут"
        }

        dynamic main_system "UC05" "Получение маршрутов пользователя" {
            autoLayout
            user -> main_system.gateway "Получение маршрутов пользователя (GET /paths)"
            main_system.gateway -> main_system.path_service "Запрос маршрутов"
            main_system.path_service -> main_system.poput_db "Получить маршруты"
        }

        dynamic main_system "UC06" "Создание поездки" {
            autoLayout
            user -> main_system.gateway "Создание поездки (POST /trip)"
            main_system.gateway -> main_system.trip_service "Создание поездки"
            main_system.trip_service -> main_system.poput_db "Создать новую поездку"
        }

        dynamic main_system "UC07" "Подключение пользователей к поездке" {
            autoLayout
            user -> main_system.gateway "Подключение к поездке (PUT /trip)"
            main_system.gateway -> main_system.trip_service "Подключение к поездке"
            main_system.trip_service -> main_system.poput_db "Присоединение пользователя к поездке"
        }
        
        dynamic main_system "UC08" "Получение информации о поездке" {
            autoLayout
            user -> main_system.gateway "Получение информации о поездке (GET /trip?id=<uuid>)"
            main_system.gateway -> main_system.trip_service "Запрос данных о поездке"
            main_system.trip_service -> main_system.poput_db "Получение данных о поездке"
        }

        styles {
            element "database" {
                shape cylinder
            }
        }
    }
}