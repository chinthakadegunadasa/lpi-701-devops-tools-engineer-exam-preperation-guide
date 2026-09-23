graph TD
    classDef header fill:#1A237E,color:#FFFFFF,stroke:#0D47A1,stroke-width:2px;
    classDef scrum fill:#E8EAF6,color:#1A237E,stroke:#3F51B5,stroke-width:2px;
    classDef kanban fill:#E0F2F1,color:#004D40,stroke:#009688,stroke-width:2px;

    Agile["<b>AGILE PHILOSOPHY</b>"]:::header

    subgraph SCRUM_CARD ["SCRUM"]
        ScrumDetails["<b>• Time-boxed Sprints</b><br/><b>• Rigid Roles</b><br/><b>• Prescribed Events</b>"]
    end

    subgraph KANBAN_CARD ["KANBAN"]
        KanbanDetails["<b>• Continuous Flow</b><br/><b>• WIP Limits</b><br/><b>• Flexible Backlog</b>"]
    end

    Agile --> SCRUM_CARD
    Agile --> KANBAN_CARD

    class SCRUM_CARD scrum;
    class KANBAN_CARD kanban;
