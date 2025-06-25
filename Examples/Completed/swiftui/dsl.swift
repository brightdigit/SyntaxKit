Import("SwiftUI").access("public")

Struct("TodoItemRow") {
  Variable(.let, name: "item", type: "TodoItem").access("private")
  
  Variable(.let, name: "onToggle", type:
            ClosureType(returns: "Void"){
    ClosureParameter("Date")
  }
    .attribute("@MainActor")
    .attribute("@Sendable")
  )
  .access("private")
  
  ComputedProperty("body", type: "some View") {
    Init("HStack") {
      ParameterExp(unlabeled: Closure{
        ParameterExp(unlabeled: Closure{
          Init("Button") {
            ParameterExp(name: "action", value: VariableExp("onToggle"))
            ParameterExp(unlabeled: Closure{
              Init("Image") {
                ParameterExp(name: "systemName", value: ConditionalOp(
                  if: VariableExp("item").property(name: "isCompleted"),
                  then: Literal.string("checkmark.circle.fill"),
                  else: Literal.string("circle")
                ))
              }.call("foregroundColor"){
                ParameterExp(unlabeled: ConditionalOp(
                  if: VariableExp("item").property(name: "isCompleted"),
                  then: EnumCase("green"),
                  else: EnumCase("gray")
                ))
              }
            })
          }
          Init("Button") {
            ParameterExp(name: "action", value: Closure {
              Init("Task") {
                ParameterExp(unlabeled: Closure(
                  capture: {
                    ParameterExp(unlabeled: VariableExp("self").reference("weak"))
                  },
                  body: {
                    VariableExp("self").optional().call("onToggle") {
                      ParameterExp(unlabeled: Init("Date"))
                    }
                  }
                ).attribute("@MainActor"))
              }
            })
            ParameterExp(unlabeled: Closure {
              Init("Image") {
                ParameterExp(name: "systemName", value: Literal.string("trash"))
              }
            })
          }
        })
      })
      
    }
  }
}
.inherits("View")
.access("public")
