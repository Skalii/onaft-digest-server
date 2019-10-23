package skalii.restful.onaftdigestserver.entity


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


@Entity(name = "Author")
@JsonPropertyOrder(
        value = ["id_author", "full_name", "publications"])
@SequenceGenerator(
        name = "authors_seq",
        sequenceName = "authors_id_author_seq",
        schema = "public",
        allocationSize = 1)
@Table(
        name = "authors",
        schema = "public",
        indexes = [
            Index(name = "authors_pkey",
                    columnList = "id_author",
                    unique = true),
            Index(name = "authors_id_author_uindex",
                    columnList = "id_author",
                    unique = true),
            Index(name = "authors_full_name_uindex",
                    columnList = "full_name",
                    unique = true)])
data class Author(

        @Column(name = "id_author",
                nullable = false)
        @GeneratedValue(
                strategy = GenerationType.SEQUENCE,
                generator = "authors_seq")
        @Id
        @get:JsonProperty(value = "id_author")
        @NotNull
        val idAuthor: Int = 0,

        @Column(name = "full_name",
                nullable = false)
        @get:JsonProperty(value = "full_name")
        @NotNull
        val fullName: String = ""

) {

    @JoinTable(
            name = "publications_authors",
            joinColumns = [JoinColumn(
                    name = "id_author",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_authors_id_author_fkey"))],
            inverseJoinColumns = [JoinColumn(
                    name = "id_publication",
                    nullable = false,
                    foreignKey = ForeignKey(name = "publications_publications_id_publication_fkey"))])
    @JsonIgnoreProperties(value = ["author"])
    @get:JsonProperty(value = "publications")
    @ManyToMany(cascade = [CascadeType.ALL])
    lateinit var publications: MutableList<Publication>

    constructor() : this(
            0,
            ""
    )
}