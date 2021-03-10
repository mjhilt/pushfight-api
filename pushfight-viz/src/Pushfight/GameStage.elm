module Pushfight.GameStage exposing (GameStage(..), isSetup, isGameOver, isWhiteTurn, isBlackTurn)

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

-- TODO GameStage Encoder/Decoder
