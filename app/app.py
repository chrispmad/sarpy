# PART 4 - Exercise 1
# ///////////////////

from shiny import App, ui, reactive, render, req
import pandas as pd
from shinywidgets import render_widget, output_widget

app_ui = ui.page_fluid(
    
)


def server(input, output, session):
    pass
    #  Start with empty data frame
    #todos = reactive.value(pd.DataFrame())
    #selected_row_reactive = reactive.value("BLROP")
#
    #@reactive.calc
    #@render.data_frame
    #def dt():
    #    return render.DataTable(todos(), selection_mode='row')
    #
    ## Add a new todo
    #@reactive.effect
    #@reactive.event(input.add)
    #def _():
    #    req(input.task().strip())
    #    newTask = pd.DataFrame(
    #        {
    #            "created": [datetime.now().strftime("%Y-%m-%d %H:%M:%S")],
    #            "task": [input.task()],
    #            "completed": [None],
    #        }
    #    )
    #    todos.set(pd.concat([todos(), newTask], ignore_index=True))
    #    ui.update_text("task", value="")


app = App(app_ui, server, static_assets="app\\www\\")
