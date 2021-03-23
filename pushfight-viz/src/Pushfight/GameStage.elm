module Pushfight.GameStage exposing (GameStage(..), isSetup, isGameOver, isWhiteTurn, isBlackTurn, encode, decode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode

type GameStage
    = WhiteSetup
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
        "whiteSetup" ->
            Decode.succeed WhiteSetup
        "blackSetup" ->
            Decode.succeed BlackSetup
        "whiteTurn" ->
            Decode.succeed WhiteTurn
        "blackTurn" ->
            Decode.succeed BlackTurn
        "whiteWon" ->
            Decode.succeed WhiteWon
        "blackWon" ->
            Decode.succeed BlackWon
        "draw" ->
            Decode.succeed Draw
        other ->
            Decode.fail <|
                "Unable to interpret game stage: " ++ other

encode : GameStage -> Encode.Value
encode gs =
    case gs of
        WhiteSetup ->
            Encode.string "whiteSetup"
        BlackSetup ->
            Encode.string "blackSetup"
        WhiteTurn ->
            Encode.string "whiteTurn"
        BlackTurn ->
            Encode.string "blackTurn"
        WhiteWon ->
            Encode.string "whiteWon"
        BlackWon ->
            Encode.string "blackWon"
        Draw ->
            Encode.string "draw"
