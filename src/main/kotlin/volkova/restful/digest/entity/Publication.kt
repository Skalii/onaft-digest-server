package volkova.restful.digest.entity


import com.fasterxml.jackson.annotation.JsonFormat
import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import com.fasterxml.jackson.annotation.JsonPropertyOrder

import java.util.Date

import javax.persistence.CascadeType
import javax.persistence.Column
import javax.persistence.Convert
import javax.persistence.Entity
import javax.persistence.FetchType
import javax.persistence.ForeignKey
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id
import javax.persistence.Index
import javax.persistence.JoinColumn
import javax.persistence.JoinTable
import javax.persistence.ManyToMany
import javax.persistence.ManyToOne
import javax.persistence.OneToOne
import javax.persistence.SequenceGenerator
import javax.persistence.Table
import javax.validation.constraints.NotNull

import volkova.restful.digest.entity.enum.PublicationType


@Entity(name = "Publication")
@JsonPropertyOrder(
        value = ["id_publication", "type", "title", "abstract",
            "date", "doi", "rating", "journal", "authors", "keywords"])
@SequenceGenerator(
        name = "publications_seq",
        sequenceName = "publications_id_publication_seq",
        schema = "public",
        allocationSize = 1)
@Table(
        name = "publications",
        schema = "public",
        indexes = [
            Index(name = "publications_pkey",
                    columnList = "id_publication",
                    unique = true),
            Index(name = "publications_id_publication_uindex",
                    columnList = "id_publication",
                    unique = true),
            Index(name = "publication_doi_uindex",
                    columnList = "doi",
                    unique = true),
            Index(name = "publications_id_rating_uindex",
                    columnList = "id_rating",
                    unique = true)])
data class Publication(

        @Column(name = "id_publication",
                nullable = false)
        @GeneratedValue(
                strategy = GenerationType.SEQUENCE,
                generator = "publications_seq")
        @Id
        @get:JsonProperty(value = "id_publication")
        @NotNull
        val idPublication: Int = 0,

        @Column(name = "type",
                nullable = false)
        @Convert(converter = PublicationType.Companion.EnumConverter::class)
        @get:JsonProperty(value = "type")
        @NotNull
        val type: PublicationType = PublicationType.ARTICLE,

        @Column(name = "title",
                nullable = false)
        @get:JsonProperty(value = "title")
        @NotNull
        val title: String = "",

        @Column(name = "abstract")
        @get:JsonProperty(value = "abstract")
        val abstract: String = "",

        @Column(name = "date")
        @get:JsonFormat(
                pattern = "yyyy-MM-dd",
                shape = JsonFormat.Shape.STRING,
                timezone = "Europe/Kiev")
        @get:JsonProperty(value = "date")
        val date: Date? = null,

        @Column(name = "doi")
        @get:JsonProperty(value = "doi")
        val doi: String? = null

) {

    @JoinColumn(
            name = "id_rating",
            nullable = false,
            foreignKey = ForeignKey(name = "publications_ratings_id_rating_fkey"))
    @JsonIgnoreProperties(value = ["publication"])
    @get:JsonProperty(value = "rating")
    @OneToOne(
            targetEntity = Rating::class,
            fetch = FetchType.EAGER,
            optional = false)
    lateinit var rating: Rating

    @JoinColumn(
            name = "id_journal",
            foreignKey = ForeignKey(name = "publications_journals_id_journal_fkey"))
    @JsonIgnoreProperties(value = ["publications"])
    @get:JsonProperty(value = "journal")
    @ManyToOne(
            targetEntity = Journal::class,
            fetch = FetchType.EAGER)
    var journal: Journal? = null

    @JoinTable(
            name = "publications_authors",
            joinColumns = [JoinColumn(
                    name = "id_publication",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_authors_id_publication_fkey"))],
            inverseJoinColumns = [JoinColumn(
                    name = "id_author",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_authors_id_author_fkey"))])
    @JsonIgnoreProperties(value = ["publications"])
    @get:JsonProperty(value = "authors")
    @ManyToMany(cascade = [CascadeType.ALL])
    lateinit var authors: MutableList<Author>

    @JoinTable(
            name = "publications_keywords",
            joinColumns = [JoinColumn(
                    name = "id_publication",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_keywords_id_publication_fkey"))],
            inverseJoinColumns = [JoinColumn(
                    name = "id_keyword",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_keywords_id_keyword_fkey"))])
    @JsonIgnoreProperties(value = ["publications"])
    @get:JsonProperty(value = "keywords")
    @ManyToMany(cascade = [CascadeType.ALL])
    lateinit var keywords: MutableList<Keyword>


    constructor() : this(
            0,
            PublicationType.ARTICLE,
            "",
            "",
            null,
            null
    )

    constructor(
            idPublication: Int = 0,
            type: PublicationType = PublicationType.ARTICLE,
            title: String = "",
            abstract: String = "",
            date: Date? = null,
            doi: String? = null,
            rating: Rating = Rating(),
            journal: Journal = Journal()

    ) : this(
            idPublication,
            type,
            title,
            abstract,
            date,
            doi
    ) {
        this.rating = rating
        this.journal = journal
    }

}