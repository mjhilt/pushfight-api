module Page.PlayingGame exposing (Model, Msg, init, subscriptions, toSession, update, view)

--import Html.Events exposing (onInput)
--import Pushfight.Color exposing (Color(..))

import Api exposing (Cred)
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


type alias Model =
    { session : Session
    , gameId : String
    , gameState : GameState
    }


type GameState
    = Loading
    | Loaded Game.Model



init : Session -> String -> ( Model, Cmd Msg )
init session gameId =
    ( { session = session
      , gameId = gameId
      , gameState = Loading
      }
    , Cmd.none
    )



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Game " ++ model.gameId
    , content =
        div []
            [ div [] [ text "Let's play some pushfight!" ]
            , div [] [ button [ onClick BackToLobby ] [ text "Back To Lobby" ] ]
            ]
    }



-- UPDATE


type alias Wakka =
    { board : Board.Board
    , moves : List Move
    , gameStage : GameStage
    , request : Request
    }


type Msg
    = BackToLobby
    | GotSession Session
    | GotGameMsg Game.Msg
    | GameFromServer Wakka
    | MovePosted (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BackToLobby ->
            ( model, Route.replaceUrl (Session.navKey model.session) Route.Home )

        GotSession session ->
            ( { model | session = session }, Cmd.none )

        GotGameMsg gmsg ->
            case model.gameState of
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
                    ( { model | gameState = Loaded newGame }, gameCmd )

        MovePosted _ ->
            ( model, Cmd.none )

        GameFromServer _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Session.changes GotSession (Session.navKey model.session)
        , Sub.map GotGameMsg Game.subscriptions
        ]



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
