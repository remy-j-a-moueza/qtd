#! /bin/bash

dmd main.d addressbook.d -I../../../../ -I../../../../qt/d1 -L-L../../../../lib -L-lqtdgui -L-lqtdcore -L-lQtCore -L-lQtGui -ofaddressbook
