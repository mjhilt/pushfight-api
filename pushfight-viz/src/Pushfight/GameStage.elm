module Pushfight.GameStage exposing (GameStage(..), decode, encode, isBlackTurn, isGameOver, isSetup, isWhiteTurn)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type GameStage
    = WaitingForPlayers
    | WhiteSetup
    | BlackSetup
    | WhiteTurn
    | BlackTurn
    | WhiteWon
    | BlackWon
    | Draw


isSetup : GameStage -> Bool
isSetup gameStage =
    case gameStage of
        WhiteSetup ->
            True

        BlackSetup ->
            True

        _ ->
            False


isGameOver : GameStage -> Bool
isGameOver gameStage =
    case gameStage of
        WhiteWon ->
            True

        BlackWon ->
            True

        Draw ->
            True

        _ ->
            False


isWhiteTurn : GameStage -> Bool
isWhiteTurn gameStage =
    case gameStage of
        WhiteSetup ->
            True

        WhiteTurn ->
            True

        _ ->
            False


isBlackTurn : GameStage -> Bool
isBlackTurn gameStage =
    case gameStage of
        BlackSetup ->
            True

        BlackTurn ->
            True

        _ ->
            False


decode : Decoder GameStage
decode =
    Decode.field "gameStage" Decode.string
        |> Decode.andThen decodeGameStageImpl


decodeGameStageImpl : String -> Decoder GameStage
decodeGameStageImpl gs =
    case gs of
        "waitingforplayers" ->
            Decode.succeed WaitingForPlayers

        "whitesetup" ->
            Decode.succeed WhiteSetup

        "blacksetup" ->
            Decode.succeed BlackSetup

        "whiteturn" ->
            Decode.succeed WhiteTurn

        "blackturn" ->
            Decode.succeed BlackTurn

        "whitewon" ->
            Decode.succeed WhiteWon

        "blackwon" ->
            Decode.succeed BlackWon

        "draw" ->
            Decode.succeed Draw

        other ->
            Decode.fail <|
                "Unable to interpret game stage: "
                    ++ other


encode : GameStage -> Encode.Value
encode gs =
    case gs of
        WaitingForPlayers ->
            Encode.string "waitingforplayers"

        WhiteSetup ->
            Encode.string "whitesetup"

        BlackSetup ->
            Encode.string "blacksetup"

        WhiteTurn ->
            Encode.string "whiteturn"

        BlackTurn ->
            Encode.string "blackturn"

        WhiteWon ->
            Encode.string "whitewon"

        BlackWon ->
            Encode.string "blackwon"

        Draw ->
            Encode.string "draw"
