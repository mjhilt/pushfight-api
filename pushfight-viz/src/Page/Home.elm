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
    , myGames : List String
    , openGames : List String
    , newGameData : GameChallenge
    , problems : List String
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , myGames = []
      , openGames = []
      , newGameData = { color = Nothing, timed = False, opponent = "" }
      , problems = []
      }
    , Cmd.none
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

        Just _ ->
            { title = "Lobby"
            , content =
                div []
                    [ div [] [ text "Let's play some pushfight!" ]
                    , div []
                        [ fieldset []
                            [ button [ onClick RequestNewGame ] [ text "Start New Game" ]
                            , checkbox ToggleTimed "Timed Game"
                            , radiobutton "Random" (ChangeSide Nothing) (model.newGameData.color == Nothing)
                            , radiobutton "White" (ChangeSide (Just White)) (model.newGameData.color == Just White)
                            , radiobutton "Black" (ChangeSide (Just Black)) (model.newGameData.color == Just Black)

                            --, div [style "padding" "20px"] []
                            , input [ placeholder "Opponent (optional)", value model.newGameData.opponent, onInput UpdateOpponent ] []
                            ]
                        ]
                    , ul [ class "error-messages" ] (model.problems |> List.map (\s -> li [] [ text s ]))
                    , div [] [ button [ onClick Refresh ] [ text "Refresh" ] ]
                    , div [] [ button [ onClick LogOut ] [ text "Log Out" ] ]
                    ]
            }


viewMyGames : List String -> Html Msg
viewMyGames myGames =
    List.map viewMyGamesImpl myGames
        |> div []


viewMyGamesImpl : String -> Html Msg
viewMyGamesImpl gameId =
    div [] [ text gameId, button [ onClick (JoinGame gameId) ] [ text "Go To" ] ]


viewOpenGames : List String -> Html Msg
viewOpenGames openGames =
    List.map viewOpenGamesImpl openGames
        |> div []


viewOpenGamesImpl : String -> Html Msg
viewOpenGamesImpl gameId =
    div [] [ text gameId, button [ onClick (GoToGame gameId) ] [ text "Join" ] ]


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
                [ Api.opengames GotOpenGames
                , Api.mygames GotMyGames c
                ]

        Nothing ->
            Api.opengames GotOpenGames



-- UPDATE


type Msg
    = LogOut
    | RequestNewGame
    | ChangeSide (Maybe Color)
    | ToggleTimed
    | UpdateOpponent String
    | GotSession Session
    | GotGameData (Result Http.Error Api.GameInfo)
    | GotOpenGames (Result Http.Error (List Api.OpenGame))
    | GotMyGames (Result Http.Error (List String))
    | GoToGame String
    | JoinGame String
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

        JoinGame gameID ->
            ( model, Cmd.none )

        GotSession session ->
            ( { model | session = session }, Cmd.none )

        GotOpenGames (Err error) ->
            ( model, Cmd.none )

        GotOpenGames (Ok opengames) ->
            let
                gameIds =
                    List.map (\a -> a.gameId) opengames
            in
            ( { model | openGames = gameIds }, Cmd.none )

        GotMyGames (Err error) ->
            ( model, Cmd.none )

        GotMyGames (Ok gameIds) ->
            ( { model | myGames = gameIds }, Cmd.none )

        GoToGame gameId ->
            ( model, Cmd.none )

        Refresh ->
            ( model, refresh (Session.cred model.session) )

        GotGameData (Ok game) ->
            ( model, Route.replaceUrl (Session.navKey model.session) (Route.PlayingGame game.gameId) )

        GotGameData (Err error) ->
            let
                serverErrors =
                    Api.decodeErrors error
            in
            ( { model | problems = List.append model.problems serverErrors }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
