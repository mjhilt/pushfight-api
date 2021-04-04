module Page.Home exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api exposing (Cred, GameChallenge)
import Api.Endpoint as Endpoint
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Pushfight.Color exposing (Color(..))
import Route
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import Username exposing (Username)



-- MODEL


type alias Model =
    { session : Session
    , myGames : List Api.OpenGame
    , openGames : List Api.OpenGame
    , newGameData : GameChallenge
    , problems : List String
    , lobbyView : LobbyView
    }


type LobbyView
    = MyGames
    | OpenGames
    | NewGame



-- init


init : Session -> ( Model, Cmd Msg )
init session =
    --let
    --    cmd =
    --        case Session.cred session of
    --            Just cred ->
    --                Api.mygames cred GotMyGames
    --            Nothing ->
    --                Cmd.nothing
    --in
    ( { session = session
      , myGames = []
      , openGames = []
      , newGameData = { color = Nothing, timed = False, opponent = "" }
      , problems = []
      , lobbyView = MyGames
      }
    , Session.cred session |> refresh
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    case Session.cred model.session of
        Nothing ->
            { title = "Sign In Or Register"
            , content =
                div []
                    [ div [] [ text "Welcome To Pushfight" ]
                    , div [] [ a [ Route.href Route.Login ] [ text "Login" ] ]
                    , div [] [ a [ Route.href Route.Register ] [ text "Register" ] ]
                    ]
            }

        Just cred ->
            let
                main =
                    case model.lobbyView of
                        NewGame ->
                            div []
                                [ div [] [ text "Start New Game" ]
                                , fieldset []
                                    [ button [ onClick RequestNewGame ] [ text "Start New Game" ]
                                    , checkbox ToggleTimed "Timed Game"
                                    , radiobutton "Random" (ChangeSide Nothing) (model.newGameData.color == Nothing)
                                    , radiobutton "White" (ChangeSide (Just White)) (model.newGameData.color == Just White)
                                    , radiobutton "Black" (ChangeSide (Just Black)) (model.newGameData.color == Just Black)
                                    , input [ placeholder "Opponent (optional)", value model.newGameData.opponent, onInput UpdateOpponent ] []
                                    ]
                                ]

                        MyGames ->
                            div []
                                [ div [] [ text "My Games" ]
                                , div [] [ viewMyGames model.myGames ]
                                , div [] [ button [ onClick Refresh ] [ text "Refresh" ] ]
                                ]

                        OpenGames ->
                            div []
                                [ div [] [ text "Join Open Game" ]
                                , div [] [ viewOpenGames model.openGames ]
                                , div [] [ button [ onClick Refresh ] [ text "Refresh" ] ]
                                ]
            in
            { title = "Lobby"
            , content =
                div []
                    --[ div [] [ text "Let's play some pushfight!" ]
                    [ div []
                        [ button [ onClick GoToMyGames ] [ text "My Games" ]
                        , button [ onClick GoToOpenGames ] [ text "Open Games" ]
                        , button [ onClick GoToNewGame ] [ text "New Game" ]
                        ]
                    , main
                    , ul [ class "error-messages" ] (model.problems |> List.map (\s -> li [] [ text s ]))
                    , div [] [ button [ onClick LogOut ] [ text "Log Out" ] ]
                    ]
            }


viewMyGames : List Api.OpenGame -> Html Msg
viewMyGames myGames =
    List.map viewMyGamesImpl myGames
        |> div []


viewMyGamesImpl : Api.OpenGame -> Html Msg
viewMyGamesImpl game =
    div [] [ button [ onClick (LoadGame game.gameId) ] [ "Vs " ++ game.opponent |> text ] ]


viewOpenGames : List Api.OpenGame -> Html Msg
viewOpenGames openGames =
    List.map viewOpenGamesImpl openGames
        |> div []


viewOpenGamesImpl : Api.OpenGame -> Html Msg
viewOpenGamesImpl game =
    div [] [ button [ onClick (JoinAndLoadGame game.gameId) ] [ "Vs " ++ game.opponent |> text ] ]


checkbox : msg -> String -> Html msg
checkbox msg name =
    label
        [ style "padding" "20px" ]
        [ input [ type_ "checkbox", onClick msg ] []
        , text name
        ]


radiobutton : String -> msg -> Bool -> Html msg
radiobutton value msg sel =
    label []
        [ input
            [ type_ "radio"
            , name "value"

            --, style "padding-right" "20px"
            , onClick msg
            , checked sel
            ]
            []
        , text value
        ]


refresh : Maybe Cred -> Cmd Msg
refresh cred =
    case cred of
        Just c ->
            Cmd.batch
                [ Api.opengames GotOpenGames c
                , Api.mygames GotMyGames c
                ]

        Nothing ->
            Cmd.none



-- UPDATE


type Msg
    = LogOut
    | RequestNewGame
    | ChangeSide (Maybe Color)
    | ToggleTimed
    | UpdateOpponent String
    | GotSession Session
    | GotGameData (Result Http.Error String)
    | GotOpenGames (Result Http.Error (List Api.OpenGame))
    | GotMyGames (Result Http.Error (List Api.OpenGame))
    | LoadGame String
    | JoinAndLoadGame String
    | GoToMyGames
    | GoToOpenGames
    | GoToNewGame
    | Refresh


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogOut ->
            ( model, Api.logout )

        ChangeSide color ->
            let
                gameData =
                    model.newGameData

                newGameData =
                    { gameData | color = color }
            in
            ( { model | newGameData = newGameData }, Cmd.none )

        ToggleTimed ->
            let
                gameData =
                    model.newGameData

                newGameData =
                    { gameData | timed = not gameData.timed }
            in
            ( { model | newGameData = newGameData }, Cmd.none )

        UpdateOpponent opponent ->
            let
                gameData =
                    model.newGameData

                newGameData =
                    { gameData | opponent = opponent }
            in
            ( { model | newGameData = newGameData }, Cmd.none )

        RequestNewGame ->
            case Session.cred model.session of
                Just c ->
                    let
                        cmdMsg =
                            if String.length model.newGameData.opponent == 0 then
                                Api.start model.newGameData GotGameData c

                            else
                                Api.challenge model.newGameData GotGameData c
                    in
                    ( model, cmdMsg )

                Nothing ->
                    ( model, Cmd.none )

        JoinAndLoadGame gameId ->
            case Session.cred model.session of
                Just c ->
                    --let
                    --    cmd =
                    --        Cmd.batch
                    --        [
                    --        ]
                    --in
                    ( model, Api.join gameId GotGameData c )

                Nothing ->
                    ( model, Cmd.none )

        GotSession session ->
            ( { model | session = session }, Cmd.none )

        GotOpenGames (Err error) ->
            ( model, Cmd.none )

        GotOpenGames (Ok opengames) ->
            --let
            --    gameIds =
            --        List.map (\a -> a.gameId) opengames
            --in
            ( { model | openGames = opengames }, Cmd.none )

        GotMyGames (Err error) ->
            ( model, Cmd.none )

        GotMyGames (Ok gameIds) ->
            ( { model | myGames = gameIds }, Cmd.none )

        LoadGame gameId ->
            ( model, Route.replaceUrl (Session.navKey model.session) (Route.PlayingGame gameId) )

        Refresh ->
            ( model, refresh (Session.cred model.session) )

        GotGameData (Ok gameId) ->
            ( model, Route.replaceUrl (Session.navKey model.session) (Route.PlayingGame gameId) )

        GotGameData (Err error) ->
            let
                serverErrors =
                    Api.decodeErrors error
            in
            ( { model | problems = List.append model.problems serverErrors }
            , Cmd.none
            )

        GoToNewGame ->
            ( { model | lobbyView = NewGame }, Cmd.none )

        GoToOpenGames ->
            ( { model | lobbyView = OpenGames }, Session.cred model.session |> refresh )

        GoToMyGames ->
            ( { model | lobbyView = MyGames }, Session.cred model.session |> refresh )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
