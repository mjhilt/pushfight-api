module Page.Home exposing (Model, Msg, init, subscriptions, toSession, update, view)

{-| The homepage. You can get here via either the / or /#/ routes.
-}

import Api exposing (Cred, GameChallenge, Side(..))
import Api.Endpoint as Endpoint
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)

--import Html.Attributes exposing (attribute, class, classList, href, id, placeholder)
import Html.Events exposing (onClick)
import Http
--import Loading
--import Log
--import Page
--import PaginatedList exposing (PaginatedList)
import Session exposing (Session)
import Task exposing (Task)
import Time
import Url.Builder
import Username exposing (Username)
import Route


-- MODEL


type alias Model =
    { session : Session
    , myGames : List String
    , openGames : List String
    , newGameData : GameChallenge
    }



init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , myGames = []
      , openGames = []
      , newGameData = {side = Random, timed = False, opponent = ""}
      }
    , Cmd.none
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    case Session.cred model.session of
        Nothing ->
            { title = "Sign In Or Register"
            , content = div []
                [ div [] [text "Welcome To Pushfight"]
                , div [] [ a [ Route.href Route.Login ] [ text "Login"] ]
                , div [] [ a [ Route.href Route.Register ] [ text "Register"] ]
                ]
            }
        Just _ ->
            { title = "Lobby"
            , content = div []
                [ div [] [text "Let's play some pushfight!"]
                , div [] [ fieldset []
                    [ button [onClick RequestNewGame] [text "Start New Game"]
                    , checkbox ToggleTimed "Timed Game"
                    , radiobutton "Random" (ChangeSide Random) (model.newGameData.side == Random)
                    , radiobutton "White" (ChangeSide White) (model.newGameData.side == White)
                    , radiobutton "Black" (ChangeSide Black) (model.newGameData.side == Black)
                    --, div [style "padding" "20px"] []
                    , input [ placeholder "Opponent (optional)", value model.newGameData.opponent, onInput UpdateOpponent] []
                    ]
                ]
                , div [] [button [onClick LogOut] [text "Log Out"] ]
                ]
            }

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
            ] []
        , text value
        ]

-- UPDATE

type Msg
    = LogOut
    | RequestNewGame
    | ChangeSide Side
    | ToggleTimed
    | UpdateOpponent String
    | JoinGame String
    | GotSession Session

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogOut ->
            (model, Api.logout )
        ChangeSide side ->
            let
                gameData = model.newGameData
                newGameData = {gameData | side = side}
            in
                ( { model | newGameData = newGameData }, Cmd.none)
        ToggleTimed  ->
            let
                gameData = model.newGameData
                newGameData = {gameData | timed = not gameData.timed}
            in
                ( { model | newGameData = newGameData }, Cmd.none)
        UpdateOpponent opponent ->
            let
                gameData = model.newGameData
                newGameData = {gameData | opponent = opponent}
            in
                ( { model | newGameData = newGameData }, Cmd.none)
        RequestNewGame ->
            (model, Cmd.none)
        JoinGame gameID ->
            (model, Cmd.none)
        GotSession session ->
            ({model | session = session}, Cmd.none)

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.changes GotSession (Session.navKey model.session)



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
