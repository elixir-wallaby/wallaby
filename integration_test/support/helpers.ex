defmodule Wallaby.Integration.Helpers do
  @moduledoc false

  def displayed_in_viewport?(session, %Wallaby.Query{} = query),
    do: displayed_in_viewport?(session, Wallaby.Browser.find(session, query))

  # source: https://github.com/webdriverio/webdriverio/blob/9b83046725ea9ba68f7d2e5a4207b50a798f944f/packages/webdriverio/src/scripts/isDisplayedInViewport.js
  def displayed_in_viewport?(session, %Wallaby.Element{} = element) do
    {:ok, result} =
      element.driver.execute_script(
        session,
        """
        let elem = arguments[0]
        const dde = document.documentElement
        let isWithinViewport = true

        while (elem.parentNode && elem.parentNode.getBoundingClientRect) {
            const elemDimension = elem.getBoundingClientRect()
            const elemComputedStyle = window.getComputedStyle(elem)
            const viewportDimension = {
                width: dde.clientWidth,
                height: dde.clientHeight
            }

            isWithinViewport = isWithinViewport &&
                                (elemComputedStyle.display !== 'none' &&
                                elemComputedStyle.visibility === 'visible' &&
                                parseFloat(elemComputedStyle.opacity, 10) > 0 &&
                                elemDimension.bottom > 0 &&
                                elemDimension.right > 0 &&
                                elemDimension.top < viewportDimension.height &&
                                elemDimension.left < viewportDimension.width)

            elem = elem.parentNode
        }

        return isWithinViewport
        """,
        [%{"element-6066-11e4-a52e-4f735466cecf" => element.id, "ELEMENT" => element.id}]
      )

    result
  end
end
