# Topic Memory: Personal Dialogue Profile

## Purpose

This file is a durable companion to `personal-profile-index.md`.

Use `personal-profile-index.md` for evidence, source files, factual application data, and verification routing.
Use this file for the user's self-understanding, recurring motives, preferred narrative voice, interview-style discoveries, and application positioning inferred from direct dialogue.

## Recording Rules

- Record interpreted conclusions, not raw chat logs.
- Preserve nuance and uncertainty; mark tentative interpretations as tentative until the user confirms them.
- Do not store secrets, credentials, private identifiers, raw emotional disclosures, or sensitive personal judgments.
- Prefer entries that will help with future school, work, internship, summer-camp, portfolio, resume, personal statement, recommendation, or interview preparation.
- When a new stable pattern emerges, update this file concisely and keep the source date.

## Current Dialogue Thread

Started: 2026-07-03

User intent:
- The user wants this to be a deep, iterative conversation rather than immediate portfolio production.
- The user wants Codex to ask better questions, because question quality will directly shape the accuracy of the personal profile.
- The user wants the resulting profile to help future applications for schools, jobs, internships, and summer camps from the user's own perspective.

Known starting context from existing materials:
- Existing evidence-backed profile positions the user around Southeast University, Information Engineering + English double-degree, embodied intelligence, robotics, VLA safety, reliable intelligent systems, engineering implementation, and communication ability.
- This file should go beyond that external application story and capture what the user actually values, worries about, chooses, resists, and wants to become.

## Interview Method

Ask questions in layers:

1. Identity: what the user wants to be recognized as, and what labels feel false or incomplete.
2. Origin: which early experiences made the current direction feel personally meaningful.
3. Choice: moments where the user chose a harder or stranger path instead of the default path.
4. Friction: recurring difficulties, doubts, constraints, or misunderstandings that shaped the user.
5. Taste: what kinds of work, people, systems, and environments the user naturally respects or dislikes.
6. Evidence: which stories, projects, decisions, or artifacts prove those patterns.
7. Translation: how the above should change the user's CV, portfolio, PS, interview answers, and target selection.

## Emerging Profile

### 2026-07-04 update from prior April ChatGPT dialogue

Source status:
- The following profile is derived from a user-pasted dialogue that likely happened around 2026-04.
- The user said some things have changed since then, but the core self has not changed very much.
- Treat this as a strong working profile, not a final frozen identity. Future dialogue should confirm, revise, or nuance it.

Core direction:
- The user is drawn to embodied intelligence because of the image of service robots that can enter ordinary life, not because of one isolated technical module.
- The user's imagined robot is closer to a general household/service agent than a narrow demo robot: it should understand open-ended human tasks, operate in real environments, adapt to different scenes, and avoid requiring a separate vertical codebase for every task.
- The user's attraction is to the complete loop from human intention to physical-world execution: perception, language understanding, task decomposition, skill selection, action, feedback checking, failure diagnosis, recovery, and sometimes user clarification.

Technical taste and orientation:
- The user is not primarily a pure motion-control person. Motion control is respected as a necessary body-level foundation, but it is not the user's main source of excitement.
- The user is also not primarily a pure HRI/companionship/personality person. Understanding people and life is important to the long-term robot vision, but the user's nearer technical pull is toward task completion systems.
- The user is not best described as a pure VLA/model-training person either. The user cares about robot foundation models and VLA/VLM/LLM use, but is less drawn to spending most of the time only on data pipelines, loss functions, scaling, or model training detached from execution.
- The strongest fit is embodied-agent systems: connecting high-level intelligence with executable robot skills through a closed loop.

Ranked preferences captured in the April dialogue:
- Among robot capability layers, the user preferred "brain/intelligence layer" first, "body/action layer" second, and "life/social layer" third.
- Among failure modes, the user most wanted to solve robots getting stuck after execution failure, then poor generalization across rooms/objects/phrasing, then awkward or unstable motion, then lack of long-term learning, then shallow intent understanding.
- Among work styles, the user preferred building a running system that connects LLM/VLM/VLA, skills, planners, feedback, and robot execution over starting from a single isolated algorithm. Research questions still matter, but are most compelling when they arise from system failures.
- For a three-month project, the user preferred a real or robot-like system over a pure paper/code reproduction, and also showed interest in product-form/service-scenario thinking.
- The user wanted to start directly with robot simulation rather than only a text world or a non-embodied interface prototype.

Likely best-fit role identity:
- "Embodied AI Systems Engineer" / "Robotics Agent Engineer" / "Robotics Autonomy Engineer" / "具身智能系统工程师" / "机器人智能体工程师" are closer to the user's taste than narrowly defined motion control, SLAM, embedded driver, mechanical design, or pure model-training roles.
- The user likes connecting modules rather than permanently owning only one small module. In companies, the realistic entry should still be a specific module, but the module should sit close to system architecture: task planning, agent framework, skill orchestration, autonomy stack, simulation task environment, evaluation loop, or VLM/VLA application in robot execution.
- If forced to enter through a narrower role, the user should choose a role where they can ask upstream/downstream questions: how a skill is called, how failure is reported, how world state is updated, how re-planning happens, and how the system is evaluated.

Core system question:
- The user's recurring question is not simply "how can the robot move better?" but "how can a robot receive an open human task, translate it into executable skills, verify whether the world changed as expected, and recover when reality breaks the plan?"
- A good one-sentence positioning is: the user wants to build embodied agents that complete long-horizon tasks through closed-loop planning, skill execution, world-state tracking, and failure recovery.

Learning style:
- The user is not mainly blocked by fear of math or robotics fundamentals. The stronger blockers are lack of project traction, lack of a clear route, and uncertainty about whether the long-term path should be research, engineering, or product.
- The user is likely better served by project-driven learning than by trying to finish a large stack of courses before building anything.
- The user wants "enough depth to connect modules intelligently," not shallow buzzword familiarity and not expert-level depth in every low-level field.

Knowledge-depth target for applications/interviews:
- Core layers to implement personally: task planning, skill abstraction, world-state representation, closed-loop execution, failure classification, failure recovery, and evaluation.
- Support layers to use and debug: ROS 2 concepts, simulation environment, basic perception-to-state conversion, MoveIt or basic motion planning interfaces, and simple robot execution APIs.
- Lower layers to understand at interface level: kinematics, inverse kinematics, trajectory planning, collision checking, control failure modes, SLAM/navigation boundaries, and how low-level errors should be returned to the high-level planner.
- Frontier layers to judge critically: LLM/VLM/VLA use in robotics, why one-shot LLM plans are unsafe, why execution needs verification, and why skill preconditions/effects/safety checks matter.

Project anchor:
- A strong portfolio/research-entry project for this profile would be a simulated household or tabletop robot agent with closed-loop task planning and failure recovery.
- The project should not merely show a scripted pick-and-place demo. It should show a system that accepts natural-language tasks, builds or updates world state, calls skills such as detect/pick/place/move/open/search/ask, verifies postconditions, handles failure cases, and compares performance with and without recovery.
- Valuable failure cases include object not detected, low perception confidence, unreachable target, grasp failure, collision risk, target location full, unexpected object movement, and ambiguous human instruction.

How this should affect future application writing:
- Do not flatten the user into "an AI/robotics student with several projects." The distinctive story is systems-level interest in connecting intelligence to physical execution.
- For robotics/embodied AI applications, emphasize closed-loop task execution, failure recovery, generalization, skill orchestration, and system diagnosis.
- For engineering/internship applications, emphasize module interface awareness, debugging across layers, and the ability to reason from high-level task intent down to robot execution and back up through feedback.
- For research applications, frame the user as a system-driven research profile: someone who wants to build running embodied agents and abstract research problems from where the system breaks.
- For product-leaning opportunities, mention the long-term service-robot vision, but connect it to concrete technical mechanisms rather than only futuristic language.

### 2026-08-07 research-direction update

Source status:
- The user explicitly confirmed this direction change in conversation on 2026-08-07.

Direction change:
- The user's current priority is failure-driven long-horizon embodied intelligence, especially mobile manipulation systems that can detect execution failures, estimate recoverability, choose recovery actions, verify that the nominal policy can continue, and learn from failure/recovery trajectories.
- This is not a complete break from the earlier profile. The earlier recurring concern—what a robot should do after execution goes wrong—has narrowed from a broad systems preference into a concrete research problem that can be discussed through model design, data construction, evaluation, and experimental planning.

Positioning boundary:
- ForesightSafety-VLA remains important evidence of benchmark design, robot evaluation, and system debugging, but safety evaluation alone should not be presented as the user's intended long-term identity.
- `Learning to Hand Back` is an active research proposal rather than an adopted thesis topic or completed result. Future applications must preserve that status boundary unless later evidence confirms implementation, adviser adoption, experiments, or publication.

Open questions for future dialogue:
- The research-direction change is now recorded; future dialogue should clarify what else has changed since April, especially confidence, available resources, target roles, and long-term ambition.
- Does the user still prefer simulation-first, or has recent CASIA/VLA/robotics experience shifted the entry path?
- Does the user now lean more toward architecture engineering, system-driven research, or product/technical-lead direction?
- Which existing experience best proves this profile: ForesightSafety-VLA, humanoid whole-body tracking/MuJoCo Sim2Sim, RoboCup, SRTP IoT, or a yet-to-build portfolio project?
- What emotional or personal motive sits underneath the service-robot vision: fascination with general intelligence, desire for useful machines, discomfort with brittle demos, care for everyday human life, or another motive?
