package volkova.restful.digest.entity


import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import com.fasterxml.jackson.annotation.JsonPropertyOrder

import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id
import javax.persistence.Index
import javax.persistence.OneToMany
import javax.persistence.OrderBy
import javax.persistence.SequenceGenerator
import javax.persistence.Table

import javax.validation.constraints.NotNull


@Entity(name = "Journal")
@JsonPropertyOrder(value = ["id_journal", "title", "title_en", "publications"])
@SequenceGenerator(
        name = "journals_seq",
        sequenceName = "journals_id_journal_seq",
        schema = "public",
        allocationSize = 1)
@Table(
        name = "journals",
        schema = "public",
        indexes = [
            Index(name = "journals_pkey",
                    columnList = "id_journal",
                    unique = true),
            Index(name = "journals_id_journal_uindex",
                    columnList = "id_journal",
                    unique = true),
            Index(name = "journals_title_uindex",
                    columnList = "title",
                    unique = true),
            Index(name = "journals_title_en_uindex",
                    columnList = "title_en",
                    unique = true)])
data class Journal(

        @Column(name = "id_journal",
                nullable = false)
        @GeneratedValue(
                strategy = GenerationType.SEQUENCE,
                generator = "journals_seq")
        @Id
        @get:JsonProperty(value = "id_journal")
        @NotNull
        val idJournal: Int = 0,

        @Column(name = "title",
                nullable = false)
        @get:JsonProperty(value = "title")
        @NotNull
        val title: String = "",

        @Column(name = "title_en",
                nullable = false)
        @get:JsonProperty(value = "title_en")
        @NotNull
        val titleEn: String = ""

) {

    @JsonIgnoreProperties(value = ["journal"])
    @get:JsonProperty(value = "publications")
    @OneToMany(
            targetEntity = Publication::class,
            mappedBy = "journal")
    @OrderBy
    var publications: MutableList<Publication> = mutableListOf(Publication())

    constructor() : this(
            0,
            "",
            ""
    )

}