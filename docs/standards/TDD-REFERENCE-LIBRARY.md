# TDD Reference Library — Curated Sources for AI Agent Consumption

**Version:** 1.0.0
**Created:** 2026-03-26
**Author:** Pierre Ribeiro + Claude (Desktop)
**Purpose:** RAG knowledge base for TDD methodology research and implementation
**Usage:** Claude agents should scan descriptors and fetch full content when relevant to the task at hand.

---

## 1. Core TDD Principles & Methodology

```yaml
- url: https://en.wikipedia.org/wiki/Test-driven_development
  topic: TDD comprehensive overview
  content: Full encyclopedia entry covering TDD history, Kent Beck's origins in XP (1999), Red-Green-Refactor cycle definition, relationship to unit testing, advantages/limitations, and academic references. Covers the "test-driven development mantra" and design implications.
  relevance: foundational_reference
  depth: comprehensive

- url: https://martinfowler.com/bliki/TestDrivenDevelopment.html
  topic: Martin Fowler's TDD definition
  content: Authoritative definition from Martin Fowler. Covers the self-testing code concept, the critical importance of the refactoring step, and links to related concepts like continuous integration and evolutionary design.
  relevance: authoritative_definition
  depth: concise

- url: https://martinfowler.com/bliki/BeckDesignRules.html
  topic: Kent Beck's four rules of simple design
  content: Martin Fowler's explanation of Beck's design rules that guide TDD's refactoring phase — passes tests, reveals intention, no duplication, fewest elements. Core design philosophy underlying TDD.
  relevance: design_principles
  depth: concise

- url: http://butunclebob.com/ArticleS.UncleBob.TheThreeRulesOfTdd
  topic: Uncle Bob's three laws of TDD
  content: Robert C. Martin's canonical formulation of TDD's three rules — no production code without failing test, no more test than sufficient to fail, no more production code than sufficient to pass. The nano-cycle definition.
  relevance: canonical_rules
  depth: concise

- url: https://blog.cleancoder.com/uncle-bob/2014/12/17/TheCyclesOfTDD.html
  topic: The cycles of TDD — nano, micro, meso, macro
  content: Uncle Bob's multi-scale analysis of TDD cycles. Nano-cycle (second-by-second three laws), micro-cycle (Red-Green-Refactor), meso-cycle (specific-to-generic), macro-cycle (architectural boundaries). Essential for understanding TDD's fractal nature.
  relevance: advanced_methodology
  depth: deep

- url: https://www.jamesshore.com/v2/blog/2005/red-green-refactor
  topic: Red-Green-Refactor explained by James Shore
  content: Clear explanation of each RGR phase with practical guidance on cycle duration (aim for 5 minutes or less). Covers the thinking process behind each phase and common pitfalls.
  relevance: practical_workflow
  depth: moderate

- url: https://www.freecodecamp.org/news/test-driven-development-what-it-is-and-what-it-is-not-41fa6bca02a2
  topic: TDD fundamentals and common misconceptions
  content: Covers RGR phases in depth, explains "the word test in TDD is misleading" (argues TDD is really about behavioral specification), addresses misconceptions about TDD requiring more time, and explains why BDD and TDD are essentially the same.
  relevance: misconceptions_clarification
  depth: moderate
```

---

## 2. TDD Misconceptions & Myths

```yaml
- url: https://daedtech.com/probably-misunderstanding-tdd/
  topic: Common TDD misunderstandings
  content: Addresses five major misconceptions — TDD doesn't replace QA, doesn't catch all edge cases, doesn't mean you skip architecture, isn't just about testing. Written from consulting experience visiting many development shops.
  relevance: myth_busting
  depth: moderate

- url: https://daedtech.com/what-tdd-is-and-is-not/
  topic: What TDD is and what it is not — clear boundary definitions
  content: Defines what TDD is NOT — not load testing, not writing all tests first, not a QA strategy, not comprehensive automated testing. Then defines what TDD IS — a sequence for writing code that shortens feedback loops.
  relevance: myth_busting
  depth: moderate

- url: https://www.testrail.com/blog/myths-test-driven-development/
  topic: Five myths about TDD
  content: Debunks — writing unit tests is not TDD, you don't write all tests first, TDD doesn't replace design thinking, TDD isn't just for unit tests, and the myth that TDD experience equals writing unit tests.
  relevance: myth_busting
  depth: moderate

- url: https://www.agileinstitute.com/articles/dispelling-myths-about-test-driven-development
  topic: Dispelling TDD myths from 6+ years of practice
  content: Experienced practitioner (6 years full-time TDD) addresses myths — TDD takes longer (it doesn't long-term), produces 3x more code (true but net positive), replaces design (it doesn't), and whether TDD is always appropriate.
  relevance: practitioner_experience
  depth: deep

- url: https://blog.crisp.se/2017/09/11/perlundholm/7-misconceptions-about-tdd
  topic: Seven TDD misconceptions
  content: Covers — simple code doesn't need tests (wrong — tests are specifications), write all tests first (wrong — write with implementation), tests are expensive to maintain (only if badly written), not all classes need tests (they should be covered somehow).
  relevance: myth_busting
  depth: moderate

- url: https://www.impactqa.com/blog/what-are-the-top-misconceptions-and-myths-about-tdd/
  topic: Top TDD misconceptions and myths
  content: Addresses TDD not being a design approach (it is), TDD slowing development (it reduces total lifecycle cost), unit tests for I/O dependent code being hard (separate pure logic from I/O), and TDD not replacing traditional testing.
  relevance: myth_busting
  depth: moderate

- url: https://thinksys.com/development/test-driven-development-myths/
  topic: TDD myths 2026 edition
  content: Updated perspective on TDD myths. Covers the iterative nature misconception (not all tests first), the design neglect myth (TDD promotes iterative design refinement), and the time consumption myth. Includes real-world examples.
  relevance: myth_busting_current
  depth: moderate

- url: https://medium.com/javascript-scene/5-common-misconceptions-about-tdd-unit-tests-863d5beb3ce9
  topic: Five common misconceptions about TDD and unit tests
  content: Eric Elliott's deep dive — TDD is too time-consuming (IBM/Microsoft data shows 40-90% fewer defects), you can add tests later (statistically worse), TDD guarantees bug-free code (it doesn't), and the cost of skipping tests.
  relevance: data_driven_analysis
  depth: deep

- url: https://georgestocker.com/2020/03/17/myths-and-facts-about-tdd-unit-testing-and-team-velocity/
  topic: Myths and facts about TDD, unit testing, and team velocity
  content: Data-driven analysis of TDD impact on velocity. Compares 1-hour dev + 6-hour debug vs 6-hour TDD + 0-hour debug. NZD case study showing 95% coverage with TDD vs 10-60% post-hoc. Addresses velocity concerns directly.
  relevance: data_driven_analysis
  depth: deep
```

---

## 3. AI Agent-Driven TDD Workflow

```yaml
- url: https://arxiv.org/html/2603.17973
  topic: "TDAD: Test-Driven Agentic Development — academic paper (HTML)"
  content: Groundbreaking research on AI coding agents and TDD. Discovers the "TDD Prompting Paradox" — procedural TDD instructions INCREASE regressions. Graph-based test impact analysis reduces regressions by 70%. Auto-improvement loop quadrupled resolution. Essential reading for AI+TDD integration.
  relevance: critical_research
  depth: academic

- url: https://arxiv.org/abs/2603.17973
  topic: "TDAD paper — abstract and metadata"
  content: Abstract and citation info for the TDAD paper. Quick reference for the paper's core claims and methodology.
  relevance: reference
  depth: summary

- url: https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/
  topic: Forcing Claude Code to TDD with subagent architecture
  content: Practical implementation of agentic Red-Green-Refactor using Claude Code skills and subagents. Covers context isolation problem ("context pollution"), three-agent architecture (test writer, implementer, refactorer), and phase gates. Includes actual skill.md and agent configurations.
  relevance: practical_implementation
  depth: deep

- url: https://www.nathanfox.net/p/taming-genai-agents-like-claude-code
  topic: Taming GenAI agents with TDD via CLAUDE.md configuration
  content: Shows how to embed TDD discipline into CLAUDE.md file. Covers session triggers ("remember types, function stubs, TDD first"), the Red phase (failing tests), Green phase (minimum code), and continuous TDD commitment configuration.
  relevance: practical_configuration
  depth: moderate

- url: https://stevekinney.com/courses/ai-development/test-driven-development-with-claude
  topic: TDD with Claude Code — course material
  content: Steve Kinney's course on TDD with AI agents. Covers write-tests-first workflow, confirming test failure, committing failing tests, implementing to pass, hooks for automation, CLAUDE.md configuration, and the /plan mode for proactive planning.
  relevance: training_material
  depth: moderate

- url: https://codemanship.wordpress.com/2026/01/09/why-does-test-driven-development-work-so-well-in-ai-assisted-programming/
  topic: Why TDD works especially well with AI-assisted programming
  content: Jason Gorman's analysis of why TDD is essential for AI coding. Covers cognitive load management, small steps principle, continuous testing importance, commit-on-green/revert-on-red discipline, and clarifying with examples as test basis.
  relevance: theoretical_foundation
  depth: moderate

- url: https://thenewstack.io/claude-code-and-the-art-of-test-driven-development/
  topic: Claude Code and the art of TDD — practical experience report
  content: Real-world experience using Claude Code for TDD. Demonstrates that Claude Code can follow TDD discipline, the human defines design while LLM follows instructions, and the importance of not letting the LLM run tests autonomously in a loop.
  relevance: experience_report
  depth: moderate

- url: https://medium.com/@taitcraigd/tdd-with-claude-code-model-context-protocol-fmp-and-agents-740e025f4e4b
  topic: TDD with Claude Code, MCP, and agents — pair programming
  content: Pair programming workflow with Claude Code guided by TDD. Covers human-AI shared TDD mental model, prompt engineering for TDD context, GitHub Actions CI/CD integration, and Claude's learning behavior during TDD cycles.
  relevance: workflow_integration
  depth: deep

- url: https://medium.com/@moradikor296/the-tdd-paradigm-shift-why-test-driven-development-is-claude-codes-killer-discipline-9be9616d79f6
  topic: TDD as Claude Code's killer discipline
  content: Argues TDD is the most important discipline for AI coding agents. Covers why unfocused AI development produces unreliable code, how TDD provides structure that channels AI capabilities, and CLAUDE.md configuration patterns.
  relevance: strategic_argument
  depth: moderate

- url: https://fireworks.ai/blog/eval-driven-development-with-claude-code
  topic: Eval-Driven Development with Claude Code
  content: Adapts TDD to LLM evaluation workflows. Write evals defining desired behavior before code, build agent to pass evals. Uses MCP servers for context. Demonstrates safety net against regressions when swapping models or changing prompts.
  relevance: advanced_ai_tdd
  depth: moderate

- url: https://shipyard.build/blog/e2e-testing-claude-code/
  topic: E2E testing with Claude Code using TDD workflow
  content: Practical guide to writing E2E tests with Claude Code using TDD. Shows that TDD approach produced better tests than asking Claude to analyze existing code. Covers user story → test → implementation workflow with Cypress.
  relevance: practical_e2e
  depth: moderate

- url: https://github.com/nizos/tdd-guard
  topic: TDD Guard — automated TDD enforcement for Claude Code
  content: Open-source MCP plugin that enforces TDD discipline in Claude Code. Blocks implementation code when no failing test exists, prevents adding multiple tests simultaneously. Reference implementation for TDD enforcement.
  relevance: tooling
  depth: reference

- url: https://github.com/wshobson/agents
  topic: Multi-agent orchestration for Claude Code with TDD workflows
  content: Comprehensive system with 112 specialized agents, 146 skills, and 16 workflow orchestrators. Includes TDD workflow via /conductor:implement with verification checkpoints, semantic revert, and state persistence across sessions.
  relevance: architecture_reference
  depth: reference

- url: https://alanhou.org/blog/arxiv-tdad-test-driven-agentic-development-reducing/
  topic: TDAD paper summary and analysis
  content: Accessible summary of the TDAD academic paper. Explains the TDD Prompting Paradox, graph-based impact analysis, 70% regression reduction, and auto-improvement loop results in plain language.
  relevance: paper_summary
  depth: moderate
```

---

## 4. TDD for Database Development

```yaml
- url: https://www.depesz.com/2010/06/16/test-driven-development-for-postgresql/
  topic: TDD for PostgreSQL — seminal blog post by depesz
  content: Early and influential demonstration of applying TDD methodology to PostgreSQL development using pgTAP. Shows the full Red-Green-Refactor cycle applied to database objects — functions, tables, constraints.
  relevance: foundational_database_tdd
  depth: moderate

- url: https://medium.com/@vbilopav/unit-testing-and-tdd-with-postgresql-is-easy-b6f14623b8cf
  topic: Unit testing and TDD with PostgreSQL is easy
  content: Practical guide showing that PostgreSQL TDD is straightforward. Demonstrates pgTAP usage for testing functions, procedures, and schema objects with minimal setup friction.
  relevance: practical_guide
  depth: moderate

- url: https://levelup.gitconnected.com/can-we-test-postgres-at-the-database-level-from-functions-to-indexes-heres-how-8830b56041cf
  topic: Testing PostgreSQL at the database level — functions to indexes
  content: Comprehensive guide to database-level testing in PostgreSQL. Covers testing functions, indexes, constraints, triggers, and views. Demonstrates that database objects are fully testable using TDD principles.
  relevance: comprehensive_db_testing
  depth: deep

- url: https://www.capitalone.com/tech/software-engineering/automated-postgres-unit-testing/
  topic: Capital One — automated PostgreSQL unit testing
  content: Enterprise perspective on automated PostgreSQL testing. Covers testing strategy, framework selection, CI/CD integration, and scaling database tests in a large organization.
  relevance: enterprise_practice
  depth: moderate

- url: https://aws.amazon.com/pt/blogs/database/create-a-unit-testing-framework-for-postgresql-using-the-pgtap-extension/
  topic: AWS — pgTAP unit testing framework for PostgreSQL
  content: AWS official guide to setting up pgTAP for PostgreSQL unit testing. Covers installation, configuration, test structure, assertion functions, and integration with AWS RDS/Aurora.
  relevance: cloud_database_testing
  depth: deep

- url: https://www.tigerdata.com/learn/postgresql-extensions-pgtap
  topic: pgTAP extension deep dive
  content: Comprehensive pgTAP reference covering installation, assertion functions, schema testing, function testing, and best practices for organizing database test suites.
  relevance: tool_reference
  depth: deep

- url: https://supabase.com/docs/guides/database/extensions/pgtap
  topic: Supabase — pgTAP documentation
  content: Supabase's guide to using pgTAP for database testing. Covers enabling the extension, writing tests, running test suites, and integrating with Supabase's managed PostgreSQL.
  relevance: managed_db_testing
  depth: moderate

- url: https://www.cybrosys.com/research-and-development/postgres/how-to-use-pgtap-in-postgresql-for-reliable-database-testing
  topic: How to use pgTAP for reliable database testing
  content: Step-by-step guide to pgTAP usage. Covers has_table, has_column, col_type_is, function testing, and organizing tests into test schemas with transaction rollback patterns.
  relevance: tutorial
  depth: moderate

- url: https://medium.com/@daily_data_prep/how-can-i-test-postgressql-database-objects-using-pgtap-9541caf5e85a
  topic: Testing PostgreSQL database objects using pgTAP
  content: Practical walkthrough of testing tables, views, functions, triggers, and indexes with pgTAP. Includes code examples and assertion patterns.
  relevance: practical_examples
  depth: moderate

- url: https://medium.com/engineering-on-the-incline/unit-testing-postgres-with-pgtap-af09ec42795
  topic: Unit testing Postgres with pgTAP
  content: Engineering team's experience implementing pgTAP. Covers setup, writing meaningful tests, test organization, and lessons learned from production database testing.
  relevance: experience_report
  depth: moderate

- url: https://medium.com/engineering-on-the-incline/unit-testing-functions-in-postgresql-with-pgtap-in-5-simple-steps-beef933d02d3
  topic: Unit testing PostgreSQL functions with pgTAP in 5 steps
  content: Quick-start guide — install pgTAP, create test schema, write test function, run tests, interpret results. Minimal but effective introduction to database function testing.
  relevance: quickstart
  depth: concise

- url: https://www.endpointdev.com/blog/2022/03/using-pgtap-automate-database-testing/
  topic: Using pgTAP to automate database testing
  content: Covers automation of pgTAP tests including CI/CD integration, Docker-based test environments, and automated test discovery. Practical for setting up continuous database testing.
  relevance: automation
  depth: moderate

- url: https://www.red-gate.com/simple-talk/databases/sql-server/t-sql-programming-sql-server/test-driven-database-development-why-tsqlt/
  topic: Test-driven database development with tSQLt (SQL Server)
  content: Comprehensive guide to TDD for SQL Server using tSQLt framework. Covers FakeTable, SpyProcedure, AssertEqualsTable, test classes as schemas, and transaction rollback patterns. Essential for SQL Server migration testing context.
  relevance: sql_server_tdd
  depth: deep

- url: https://tsqlt.org/146/database-test-driven-development/
  topic: tSQLt — Database TDD for SQL Server
  content: Official tSQLt documentation on database TDD. Covers test organization, assertion functions, mocking capabilities, and the full Red-Green-Refactor cycle applied to T-SQL stored procedures and functions.
  relevance: sql_server_framework
  depth: moderate

- url: https://khalilstemmler.com/articles/test-driven-development/how-to-test-code-coupled-to-apis-or-databases/
  topic: How to test code coupled to APIs or databases
  content: Addresses the core challenge of testing database-dependent code. Covers dependency inversion, repository pattern, in-memory implementations, and integration test strategies for data access layers.
  relevance: architecture_patterns
  depth: deep
```

---

## 5. TDD Comprehensive Guides & Tutorials

```yaml
- url: https://monday.com/blog/rnd/what-is-tdd/
  topic: What is TDD — comprehensive guide 2025/2026
  content: Full TDD guide covering definition, Red-Green-Refactor cycle, history (Kent Beck, XP), comparison with BDD and ATDD, benefits, challenges, and modern integration with Agile workflows. Well-structured overview.
  relevance: comprehensive_guide
  depth: deep

- url: https://monday.com/blog/rnd/test-driven-development-tdd/
  topic: Test-driven development (TDD) — complete implementation guide
  content: Detailed TDD implementation guide with step-by-step cycle explanation, best practices, integration with modern development workflows, and practical tips for adoption.
  relevance: implementation_guide
  depth: deep

- url: https://www.virtuosoqa.com/post/test-driven-development
  topic: TDD principles, practices, and benefits
  content: Covers Red-Green-Refactor workflow, TDD vs BDD vs ATDD comparison, Agile/DevOps integration, test code quality (readable, DRY, no duplication), and speed optimization strategies (in-memory databases, parallelization).
  relevance: comprehensive_reference
  depth: deep

- url: https://circleci.com/blog/test-driven-development-tdd/
  topic: CircleCI — TDD explained with CI/CD integration
  content: TDD fundamentals with strong CI/CD integration perspective. Covers how TDD feeds naturally into continuous integration pipelines, the role of test suites in deployment confidence, and the relationship between TDD and Agile.
  relevance: cicd_integration
  depth: moderate

- url: https://www.educative.io/blog/test-driven-development
  topic: TDD pros and cons — balanced analysis
  content: Balanced treatment of TDD advantages (better code quality, documentation, confidence) and limitations (learning curve, time investment, maintenance overhead). Useful for stakeholder communication about TDD adoption.
  relevance: balanced_analysis
  depth: moderate

- url: https://www.nopaccelerate.com/test-driven-development-guide-2025/
  topic: AI-powered TDD fundamentals and best practices 2025
  content: Modern TDD guide covering AI integration at every stage — test scaffolding, edge case suggestion, refactoring assistance, regression automation. Includes TDD vs BDD vs ATDD comparison and environment setup guidance.
  relevance: ai_enhanced_tdd
  depth: deep

- url: https://www.manuelkurdian.com/posts/2019-06-18-tdd-fundamentals/
  topic: TDD fundamentals — basics and workflow
  content: Clear, concise TDD fundamentals covering the cycle, benefits, and practical workflow. Good for quick reference and onboarding new practitioners.
  relevance: fundamentals
  depth: concise
```

---

## 6. Testing Taxonomy & Patterns

```yaml
- url: https://martinfowler.com/articles/practical-test-pyramid.html
  topic: The practical test pyramid — Martin Fowler
  content: Definitive reference on the testing pyramid. Covers unit, integration, and E2E test layers, cost-per-bug analysis, the ice cream cone anti-pattern, and practical guidance on test distribution across layers.
  relevance: authoritative_taxonomy
  depth: deep

- url: https://circleci.com/blog/unit-testing-vs-integration-testing/
  topic: Unit testing vs integration testing
  content: Clear comparison of unit and integration testing — scope, speed, isolation, complexity, when to use each. Includes practical examples and recommendations for test suite balance.
  relevance: testing_comparison
  depth: moderate

- url: https://circleci.com/blog/functional-vs-non-functional-testing/
  topic: Functional vs non-functional testing
  content: Distinguishes functional testing (what the system does) from non-functional testing (how it performs). Covers performance, security, usability, reliability testing categories and their relationship to TDD.
  relevance: testing_taxonomy
  depth: moderate

- url: https://automationpanda.com/2020/07/07/arrange-act-assert-a-pattern-for-writing-good-tests/
  topic: Arrange-Act-Assert pattern for writing good tests
  content: Definitive guide to AAA pattern. Covers three phases (setup, execution, verification), rules (no Act-Assert-Act-Assert), BDD equivalent (Given-When-Then), and anti-patterns to avoid.
  relevance: test_structure_pattern
  depth: moderate

- url: https://enterprisecraftsmanship.com/posts/you-naming-tests-wrong/
  topic: Test naming conventions — Vladimir Khorikov
  content: Argues against rigid naming conventions (MethodName_Scenario_ExpectedBehavior) in favor of plain English sentences. Covers what makes a good test name, readability over structure, and practical examples.
  relevance: test_quality
  depth: moderate

- url: https://shiftasia.com/column/unit-integration-e2e-testing-guide/
  topic: Unit vs integration vs E2E testing — complete guide
  content: Comprehensive comparison of three testing levels with clear definitions, scope boundaries, execution speed, setup complexity, and recommendations for distribution in a test suite.
  relevance: testing_comparison
  depth: moderate
```

---

## 7. TDD in Specialized Domains

```yaml
- url: https://www.hashicorp.com/en/resources/test-driven-development-tdd-for-infrastructure
  topic: TDD for infrastructure (HashiCorp)
  content: HashiCorp's perspective on applying TDD to Infrastructure as Code. Covers Terraform testing approaches, plan-mode validation, integration testing for provisioned resources, and IaC test layers.
  relevance: infrastructure_tdd
  depth: moderate

- url: https://codingcube.medium.com/test-driven-terraform-503217d50bf7
  topic: Test-driven Terraform
  content: Practical guide to applying TDD principles to Terraform configurations. Covers writing tests for infrastructure state, plan-mode assertions, and multi-layer testing (unit, contract, integration, acceptance).
  relevance: terraform_tdd
  depth: moderate

- url: https://learn.microsoft.com/en-us/azure/developer/terraform/best-practices-testing-overview
  topic: Microsoft Learn — Terraform testing best practices
  content: Microsoft's official guidance on testing Terraform code. Covers static analysis, unit testing, integration testing, and acceptance testing layers with Azure-specific examples.
  relevance: cloud_iac_testing
  depth: moderate

- url: https://lakefs.io/blog/acceptance-testing-for-data-pipelines/
  topic: Testing data pipelines — overview and challenges
  content: Covers unique challenges of testing data pipelines — data dependency, state management, schema evolution. Discusses acceptance testing, data quality validation, and contract testing for pipeline stages.
  relevance: data_pipeline_testing
  depth: moderate

- url: https://medium.com/@brunouy/the-essential-role-of-automated-tests-in-data-pipelines-bb7b81fbd21b
  topic: Automated tests in data pipelines
  content: Covers unit testing transformation logic, contract testing between pipeline stages, integration testing for data flows, and data quality checks as ongoing production tests.
  relevance: data_pipeline_testing
  depth: moderate

- url: https://rebelion.la/test-driven-development-tdd-in-an-api-first-approach
  topic: TDD in an API-first approach
  content: Applies TDD methodology to API-first development. Covers defining API contracts first, writing tests against contract, implementing to pass, and contract testing between services.
  relevance: api_development
  depth: moderate

- url: https://the.agilesql.club/2019/07/how-do-we-test-etl-pipelines-part-one-unit-tests/
  topic: How to test ETL pipelines — unit tests
  content: Practical guide to unit testing ETL/ELT pipelines. Covers extracting transformation logic into pure functions, testing with known inputs/outputs, and isolating data access from business logic.
  relevance: etl_testing
  depth: moderate
```

---

## 8. TDD + BDD + DDD + ATDD Integration

```yaml
- url: https://medium.com/@sharmapraveen91/tdd-vs-bdd-vs-ddd-in-2025-choosing-the-right-approach-for-modern-software-development-6b0d3286601e
  topic: TDD vs BDD vs DDD in 2025 — choosing the right approach
  content: Comprehensive comparison of TDD, BDD, and DDD. Covers when to use each, combination strategies (TDD+BDD, TDD+DDD, BDD+DDD, all three), and 2025 trends toward blending methodologies.
  relevance: methodology_comparison
  depth: deep

- url: https://www.ramotion.com/blog/tdd-vs-bdd/
  topic: TDD vs BDD — practices and differences
  content: Clear comparison of TDD and BDD approaches. TDD focuses on code correctness via developer tests; BDD focuses on system behavior via stakeholder-readable specifications. Covers the "double loop" integration pattern.
  relevance: tdd_bdd_comparison
  depth: moderate

- url: https://circleci.com/blog/how-to-test-software-part-ii-tdd-and-bdd/
  topic: How to test software — TDD and BDD
  content: CircleCI's guide to combining TDD and BDD. Covers the relationship between unit-level TDD and feature-level BDD, tooling for each, and how they complement each other in CI pipelines.
  relevance: combined_workflow
  depth: moderate

- url: https://circleci.com/blog/what-is-behavior-driven-development/
  topic: What is BDD — CircleCI
  content: BDD fundamentals — Given-When-Then syntax, stakeholder collaboration, acceptance criteria definition, and the relationship between BDD scenarios and underlying TDD implementation.
  relevance: bdd_fundamentals
  depth: moderate

- url: https://craftbettersoftware.com/p/the-tdd-debate
  topic: The TDD debate — testing, design, or development tool?
  content: Deep analysis of TDD as simultaneously a testing approach, design technique, and development methodology. Covers the three laws, design aspects in each RGR phase, and addresses the naming debate (Test-Driven Design vs Development).
  relevance: philosophical_analysis
  depth: deep

- url: https://tdd.mooc.fi/5-advanced/
  topic: TDD MOOC — advanced techniques
  content: University-level advanced TDD material. Covers TDD with larger problems, legacy code, data-driven testing, mutation testing, and combining TDD with other methodologies. Academic depth with practical exercises.
  relevance: advanced_techniques
  depth: deep
```

---

## 9. TDD Best Practices, Design & Limitations

```yaml
- url: https://www.codurance.com/publications/2018/05/26/should-we-always-use-tdd-to-design
  topic: Should we always use TDD to design?
  content: Sandro Mancuso's nuanced analysis of TDD's role in design. Covers Classicist vs Mockist schools, when emergent design works vs when upfront design is needed, and the limits of TDD as a design tool.
  relevance: design_philosophy
  depth: deep

- url: https://www.daanstolp.nl/articles/2022/tdd-and-software-design/
  topic: TDD and software design
  content: Explores the relationship between TDD and design quality. Covers how test difficulty signals design problems, the role of refactoring in design improvement, and when TDD alone isn't sufficient for good design.
  relevance: design_relationship
  depth: moderate

- url: https://blog.ncrunch.net/post/when-not-to-use-tdd.aspx
  topic: When to use TDD and when not to
  content: Pragmatic analysis of TDD applicability. Covers scenarios where TDD excels (business logic, algorithms, APIs) and where it may not be optimal (exploratory coding, UI prototyping, spike work, one-off scripts).
  relevance: pragmatic_guidance
  depth: moderate

- url: https://www.niceideas.ch/roller2/badtrash/entry/tdd-test-driven-development-is
  topic: TDD reduces total cost of ownership of software development
  content: Business case for TDD focused on TCO reduction. Covers maintenance cost reduction, defect prevention economics, and long-term productivity gains. Useful for stakeholder justification.
  relevance: business_case
  depth: moderate

- url: https://ingeniusoftware.com/benefits-and-limitations-of-tdd/
  topic: Eight benefits and limitations of TDD
  content: Balanced analysis of TDD benefits (code quality, documentation, confidence, design) and limitations (learning curve, initial time cost, maintenance overhead, difficulty with legacy code).
  relevance: balanced_analysis
  depth: moderate

- url: https://www.infoq.com/articles/test-driven-design-java/
  topic: TDD is really a design technique — InfoQ
  content: Argues TDD is primarily a design activity, not a testing activity. Covers how test-first thinking shapes interfaces, drives decoupling, and produces better abstractions.
  relevance: design_argument
  depth: moderate

- url: https://dev.to/toureholder/the-really-effective-part-of-tdd-is-not-so-much-whether-you-write-the-test-first-according-to-uncle-bob-3h6n
  topic: The really effective part of TDD — Uncle Bob's perspective
  content: Uncle Bob's view that TDD's power comes not just from writing tests first but from the discipline of very small cycles and the confidence they create. Covers the nano-cycle perspective.
  relevance: core_philosophy
  depth: concise

- url: https://www.simpliaxis.com/resources/principles-of-test-driven-development
  topic: Mastering TDD principles
  content: Covers TDD's three rules, the RGR cycle, Agile alignment, and practical implementation guidance. Accessible introduction for teams adopting TDD.
  relevance: introduction
  depth: moderate

- url: https://www.thedroidsonroids.com/blog/key-laws-of-tdd
  topic: Key laws of TDD — discussion about common disagreements
  content: Examines areas of disagreement among TDD practitioners — strictness of the three laws, unit definition, mocking strategies, and when to break TDD rules pragmatically.
  relevance: advanced_discussion
  depth: moderate
```

---

## 10. TDD + CI/CD Pipeline Integration

```yaml
- url: https://medium.com/@hivemind_tech/how-ci-cd-empowers-test-driven-development-a96c8ae1ad91
  topic: How CI/CD empowers TDD
  content: Covers the symbiotic relationship between TDD and CI/CD. TDD produces the test suite; CI/CD runs it automatically. Covers pipeline stages, quality gates, deployment confidence, and feedback loop acceleration.
  relevance: integration_guide
  depth: moderate

- url: https://continuousdelivery.com/foundations/test-automation/
  topic: Continuous testing — continuous delivery foundations
  content: Jez Humble's perspective on test automation as a foundation for continuous delivery. Covers the role of TDD-produced tests in deployment pipelines, testing pyramid in CI context, and feedback cycle optimization.
  relevance: foundational_reference
  depth: moderate

- url: https://www.jetbrains.com/teamcity/ci-cd-guide/automated-testing/
  topic: Automated testing in continuous delivery — JetBrains
  content: JetBrains guide to automated testing in CD pipelines. Covers test categorization, execution strategies, parallelization, and how TDD-produced tests integrate into build verification.
  relevance: cicd_tooling
  depth: moderate

- url: https://www.scaleway.com/en/blog/7-best-practices-to-set-up-your-first-ci-cd-pipeline/
  topic: CI/CD pipeline best practices
  content: Covers pipeline setup including test stages, quality gates, deployment strategies, and how automated test suites (produced by TDD) serve as the backbone of reliable CI/CD.
  relevance: pipeline_setup
  depth: moderate

- url: https://elice.io/en/newsroom/softwaretest_tdd
  topic: Software testing and TDD
  content: Overview connecting software testing methodology with TDD practice. Covers testing levels, automation strategies, and how TDD fits into broader software quality assurance.
  relevance: testing_overview
  depth: moderate
```

---

## Usage Notes for Claude Agents

When processing a task related to TDD methodology:

1. **Scan the relevant section** based on the task domain (database, AI agent, CI/CD, etc.).
2. **Read the `content` descriptor** to determine if the source has the information needed.
3. **Fetch full content via `web_fetch`** only when the descriptor indicates high relevance to the current task.
4. **Prefer authoritative sources** (Martin Fowler, Uncle Bob, Kent Beck, academic papers) over general blog posts for foundational claims.
5. **For AI agent TDD**, prioritize Section 3 sources — especially the TDAD paper and the alexop.dev subagent architecture article.
6. **For database TDD**, prioritize Section 4 sources — especially pgTAP and tSQLt references.
7. **Cross-reference** multiple sources when making methodology decisions — no single source covers all perspectives.

---

*End of TDD Reference Library v1.0.0*
