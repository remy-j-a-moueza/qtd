#! /bin/bash

dmd main.d graphwidget.d node.d edge.d -L-lqtdgui -L-lqtdcore -L-lcpp_core -L-lcpp_gui -L-lQtGui -L-lQtCore -ofelasticnodes

