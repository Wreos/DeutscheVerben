import SwiftUI
import VerbTrainerCore

struct RulesView: View {
    var body: some View {
        Text(
            L10n.text(
                "Recall Präteritum for ich / er / sie / es without the pronoun. In the Partizip II field, enter hat or ist followed by the participle for the given context. Haben and sein are also accepted."
            )
        )
        Text(
            L10n.text(
                "Case, extra spaces and trailing . ! ? do not affect grading. You can use ae / oe / ue for ä / ö / ü and ss for ß."
            )
        )
        Text(
            L10n.text(
                "One letter error earns 9/10 for a verb form. More than one earns 0/10. The auxiliary is checked separately. The overall score averages Präteritum, Partizip II and the auxiliary."
            )
        )
        Text(
            L10n.text(
                "I don't know checks what you have entered. Study forms reveals the answer and marks the attempt as assisted."
            ))
        Text(
            L10n.text(
                "After forms are revealed, further answers on the same day are assisted. Viewing forms in the table or opening an old answer marks the rest of the session as assisted."
            )
        )
        Text(
            L10n.text(
                "Follow the review schedule in Progress. Successes increase intervals. After an error, the verb returns tomorrow. Mistakes and due verbs come first."
            )
        )
    }
}
