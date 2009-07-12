import qt.core.QCoreApplication;

version(Tango) {} else { import std.stdio; }

int main(string[] args)
{
    auto app = new QCoreApplication(args);
    
    auto parent = new QObject();
    parent.setObjectName("papa");
    auto child1 = new QObject(parent);
    child1.setObjectName("child1");
    auto child2 = new QObject(parent);
    child2.setObjectName("child2");
    auto child3 = new QObject(parent);
    child3.setObjectName("child3");
    
    auto cd = parent.children;
    
    writeln(app.arguments);
    foreach(child; cd)
        writeln(child.objectName);
    
    app.setLibraryPaths(["freakin", "bloody", "awesome!"]);

    writeln(app.libraryPaths);
    
    return 5;
//    return app.exec();
}
