defmodule RippleWeb.ErrorView do
  use RippleWeb, :view

  def render("403.json", %{message: message}) do
    %{errors: %{detail: message}}
  end

  def render("404.json", %{message: message}) do
    %{errors: %{detail: message}}
  end

  def render("404.json", _) do
    %{errors: %{detail: "Page not found"}}
  end

  def render("422.json", %{message: message}) do
    %{errors: %{detail: message}}
  end

  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal server error"}}
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render("500.json", assigns)
  end
end
