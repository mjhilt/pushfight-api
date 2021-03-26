module Page.PlayingGame exposing (Model, Msg, init, subscriptions, toSession, update, view)

import Api exposing (Cred)
import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Pushfight.Board as Board
import Pushfight.Game as Game exposing (OutMsg(..))
import Pushfight.GameStage as GameStage exposing (GameStage)
import Pushfight.Move as Move exposing (Move)
import Pushfight.Request as Request exposing (Request)
import Route
import Session exposing (Session)
import Time



-- model


type alias Model =
    { session : Session
    , gameId : String

    --, color : Color
    , game : LoadableGame
    }


type LoadableGame
    = Loading
    | Loaded Game.Model


init : Session -> String -> ( Model, Cmd Msg )
init session gameId =
    ( { session = session
      , gameId = gameId
      , game = Loading
      }
    , Cmd.none
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    let
        pushfight =
            case model.game of
                Loading ->
                    Html.text "Loading..."

                Loaded game ->
                    Html.map GotGameMsg (Game.view game)
    in
    { title = "Game " ++ model.gameId
    , content =
        div []
            [ div [] [ pushfight ]
            , div [] [ button [ onClick BackToLobby ] [ text "Back To Lobby" ] ]
            ]
    }



-- UPDATE


type Msg
    = BackToLobby
    | GotSession Session
    | GotGameMsg Game.Msg
      --| GameFromServer Wakka
    | GameFromServer (Result Http.Error Api.GameInfo)
    | CheckServer Time.Posix
    | MovePosted (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BackToLobby ->
            ( model, Route.replaceUrl (Session.navKey model.session) Route.Home )

        GotSession session ->
            ( { model | session = session }, Cmd.none )

        GotGameMsg gmsg ->
            case model.game of
                Loading ->
                    ( model, Cmd.none )

                Loaded game ->
                    let
                        ( newGame, outMsg ) =
                            Game.update gmsg game

                        gameCmd =
                            case outMsg of
                                SendNoOp ->
                                    Cmd.none

                                SendTurnEnded ( finalBoard, finalGameStage ) ->
                                    case Session.cred model.session of
                                        Just cred ->
                                            Api.move game.gameStage game.board game.moves finalGameStage finalBoard model.gameId cred MovePosted

                                        Nothing ->
                                            Cmd.none

                                SendRequestTakeback ->
                                    Cmd.none

                                SendOfferDraw ->
                                    Cmd.none

                                SendAcceptDraw ->
                                    Cmd.none

                                SendAcceptTakeback ->
                                    Cmd.none
                    in
                    ( { model | game = Loaded newGame }, gameCmd )

        MovePosted _ ->
            ( model, Cmd.none )

        --GameFromServer _ ->
        --    ( model, Cmd.none )
        CheckServer _ ->
            case Session.cred model.session of
                Just cred ->
                    ( model, Api.status model.gameId cred GameFromServer )

                Nothing ->
                    ( model, Cmd.none )

        GameFromServer (Ok gameFromServer) ->
            let
                updatedGame =
                    case model.game of
                        Loaded game ->
                            { game
                                | board = gameFromServer.board
                                , gameStage = gameFromServer.gameStage
                                , color = gameFromServer.color
                            }

                        Loading ->
                            Game.init gameFromServer.board gameFromServer.gameStage gameFromServer.color [] 50 Request.NoRequest
            in
            ( { model | game = Loaded updatedGame }, Cmd.none )

        --init : Board.Board -> GameStage -> Color -> List Move -> Int -> Request -> Model
        --type alias Model =
        --    { board : Board.Board
        --    , gameStage : GameStage
        --    , color : Color
        --    , orientation : Orientation.Orientation
        --    , moves : List Move
        --    , dragState : DragState.Model
        --    , gridSize : Int
        --    , request : Request
        --    }
        --let
        --    gameState = Loaded
        --        {
        --        }
        --( model,  )
        GameFromServer (Err error) ->
            Debug.log (String.join " | " (Api.decodeErrors error)) ( model, Cmd.none )



--case model.game of
--    Loading ->
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Session.changes GotSession (Session.navKey model.session)
        , Sub.map GotGameMsg Game.subscriptions
        , Time.every 1000 CheckServer
        ]



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
