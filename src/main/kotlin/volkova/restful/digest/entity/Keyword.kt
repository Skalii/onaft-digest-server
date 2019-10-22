package volkova.restful.digest.entity


import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import com.fasterxml.jackson.annotation.JsonPropertyOrder

import javax.persistence.CascadeType
import javax.persistence.Column
import javax.persistence.Entity
import javax.persistence.ForeignKey
import javax.persistence.GeneratedValue
import javax.persistence.GenerationType
import javax.persistence.Id
import javax.persistence.Index
import javax.persistence.JoinColumn
import javax.persistence.JoinTable
import javax.persistence.ManyToMany
import javax.persistence.SequenceGenerator
import javax.persistence.Table

import javax.validation.constraints.NotNull


@Entity(name = "Keyword")
@JsonPropertyOrder(value = ["id_keyword", "word", "publications"])
@SequenceGenerator(
        name = "keywords_seq",
        sequenceName = "keywords_id_keyword_seq",
        schema = "public",
        allocationSize = 1)
@Table(
        name = "keywords",
        schema = "public",
        indexes = [
            Index(name = "keywords_pkey",
                    columnList = "id_keyword",
                    unique = true),
            Index(name = "keywords_id_keyword_uindex",
                    columnList = "id_keyword",
                    unique = true),
            Index(name = "keywords_word_uindex",
                    columnList = "word",
                    unique = true)])
data class Keyword(

        @Column(name = "id_keyword",
                nullable = false)
        @GeneratedValue(
                strategy = GenerationType.SEQUENCE,
                generator = "keywords_seq")
        @Id
        @get:JsonProperty(value = "id_keyword")
        @NotNull
        val idKeyword: Int = 0,

        @Column(name = "word",
                nullable = false)
        @get:JsonProperty(value = "word")
        @NotNull
        val word: String = ""

) {

    @JoinTable(
            name = "publications_keywords",
            joinColumns = [JoinColumn(
                    name = "id_keyword",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_keywords_id_keyword_fkey"))],
            inverseJoinColumns = [JoinColumn(
                    name = "id_publication",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_keywords_id_publication_fkey"))])
    @JsonIgnoreProperties(value = ["keyword"])
    @get:JsonProperty(value = "publications")
    @ManyToMany(cascade = [CascadeType.ALL])
    lateinit var publications: MutableList<Publication>

    constructor() : this(
            0,
            ""
    )

}