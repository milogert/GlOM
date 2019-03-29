module View.Sponsor exposing (render, renderBadge, renderPerkClass)

import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Html
    exposing
        ( Html
        , a
        , b
        , div
        , h3
        , h6
        , li
        , p
        , small
        , span
        , text
        , ul
        )
import Html.Attributes
    exposing
        ( class
        , href
        , title
        )
import Html.Events exposing (onCheck, onClick)
import Model.Model exposing (..)
import Model.Shared exposing (fromExpansion)
import Model.Sponsors
    exposing
        ( PerkClass
        , Sponsor
        , TeamPerk
        , VehiclePerk
        , fromPerkClass
        , getClassPerks
        )
import Model.Vehicle.Model exposing (..)
import View.Utils exposing (icon)


render : Sponsor -> Html Msg
render { name, description, perks, grantedClasses, expansion } =
    div []
        [ h3 []
            [ text name
            , text " "
            , small [] [ text <| fromExpansion expansion ]
            ]
        , p [] [ text description ]
        , ul [] <| renderPerks perks
        , p [] <|
            b [] [ text "Available Perk Classes: " ]
                :: (grantedClasses
                        |> List.map fromPerkClass
                        |> List.intersperse ", "
                        |> List.map text
                   )
        ]


renderPerks : List TeamPerk -> List (Html Msg)
renderPerks ps =
    List.map
        (\p -> li [] [ renderTeamPerk p ])
        ps


renderTeamPerk : TeamPerk -> Html Msg
renderTeamPerk { name, description } =
    span []
        [ b [] [ text <| name ++ ": " ]
        , text description
        ]


renderBadge : Maybe Sponsor -> Html Msg
renderBadge ms =
    let
        ( name, description ) =
            case ms of
                Nothing ->
                    ( "No Sponsor", "" )

                Just sponsor ->
                    ( sponsor.name, sponsor.description )
    in
    span [ class "sponsor-badge" ]
        [ a
            [ class "badge badge-secondary"
            , onClick <| To ViewSelectingSponsor
            , href "#"
            , title description
            ]
            [ text name
            , icon "exchange-alt"
            ]
        ]


renderPerkClass : CurrentView -> Vehicle -> PerkClass -> Grid.Column Msg
renderPerkClass currentView vehicle perkClass =
    Grid.col [ Col.md6 ] <|
        [ h6 [] [ text <| fromPerkClass perkClass ] ]
            ++ (getClassPerks perkClass
                    |> List.filter
                        (\perk ->
                            case ( List.member perk vehicle.perks, currentView ) of
                                ( True, _ ) ->
                                    True

                                ( False, ViewPrinterFriendly _ ) ->
                                    False

                                ( False, _ ) ->
                                    True
                        )
                    |> List.map (renderVehiclePerk vehicle)
               )


renderVehiclePerk : Vehicle -> VehiclePerk -> Html Msg
renderVehiclePerk vehicle perk =
    Checkbox.checkbox
        [ Checkbox.id perk.name
        , Checkbox.onCheck <| VehicleMsg << SetPerkInVehicle vehicle.key perk
        , Checkbox.checked <| List.member perk vehicle.perks
        ]
    <|
        perk.name
            ++ " ("
            ++ String.fromInt perk.cost
            ++ "): "
            ++ perk.description
