Feature: Hello-world greeting

  @story-1
  Rule: Only a signed-in caller may request the greeting

    Scenario: A signed-in caller receives the greeting
      Given Sam has signed in via Thunder SSO
      When Sam requests the hello-world greeting
      Then Sam receives a greeting message

    @negative
    Scenario: An unauthenticated request is refused
      Given Sam has not signed in
      When Sam requests the hello-world greeting
      Then the request is refused

  @story-1
  Rule: The greeting message is fixed

    Scenario: The greeting does not vary between callers
      Given Sam and Jordan have both signed in via Thunder SSO
      When Sam requests the hello-world greeting and Jordan requests the hello-world greeting
      Then they receive the same greeting message
